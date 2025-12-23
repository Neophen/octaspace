defmodule OctaspaceWeb.CalendarLive do
  use OctaspaceWeb, :live_view

  alias Octaspace.Mock.CalendarData
  alias OctaspaceWeb.CalendarUI

  # Maximum range is 3 months (roughly 92 days)
  @max_range_days 92

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()
    # Property start date (mock - in real app, get from property)
    min_date = Date.add(today, -365)
    # Max 2 years in the future
    max_date = Date.add(today, 730)

    {start_date, end_date} = calculate_range(:this_week, today)

    socket =
      socket
      |> assign(:today, today)
      |> assign(:min_date, min_date)
      |> assign(:max_date, max_date)
      |> assign(:range_type, :this_week)
      |> assign(:ranges, build_ranges())
      |> assign_form(start_date, end_date)
      |> update_calendar_data()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.form for={@form} phx-change="validate" phx-submit="apply-range">
        <CalendarUI.grid days={@days}>
          <:header>
            <CalendarUI.controls
              form={@form}
              ranges={@ranges}
              range_type={@range_type}
              min_date={@min_date}
              max_date={@max_date}
              prev_info={@prev_info}
              next_info={@next_info}
            />
          </:header>

          <CalendarUI.header>
            <:corner>
              <div class="mt-auto text-sm font-semibold">Rooms</div>
              <div role="tablist" class="tabs-box mt-2 tabs grid">
                <a role="tab" class="tab-active tab">Detalus</a>
                <a role="tab" class="tab">Overview</a>
              </div>
            </:corner>

            <CalendarUI.day_header
              :for={{date, index} <- dates_with_index(@start_date, @days)}
              date={date}
              stats={stats_for_date(date)}
            />
          </CalendarUI.header>

          <%= for property <- @properties do %>
            <CalendarUI.room_row
              :for={room <- property.rooms}
              room={room}
              property={Map.take(property, [:name, :icon, :color])}
              dates={@dates}
            >
              <CalendarUI.reservation_card
                :for={reservation <- room.reservations}
                reservation={reservation}
                {reservation_position(reservation, @start_date, @end_date)}
              />
            </CalendarUI.room_row>
          <% end %>
        </CalendarUI.grid>
      </.form>
    </Layouts.app>
    """
  end

  # Event handlers

  @impl true
  def handle_event("set-range", %{"range" => range_str}, socket) do
    range_type = String.to_existing_atom(range_str)

    # For custom range, keep the current dates - user will adjust via date inputs
    socket =
      if range_type == :custom do
        assign(socket, :range_type, range_type)
      else
        {start_date, end_date} = calculate_range(range_type, socket.assigns.today)

        # Clamp to allowed bounds
        start_date = clamp_date(start_date, socket.assigns.min_date, socket.assigns.max_date)
        end_date = clamp_date(end_date, socket.assigns.min_date, socket.assigns.max_date)

        socket
        |> assign(:range_type, range_type)
        |> assign_form(start_date, end_date)
        |> update_calendar_data()
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"date_range" => params}, socket) do
    socket = validate_and_update(socket, params)
    {:noreply, socket}
  end

  # Handle individual input blur events (phx-blur sends just the input value)
  @impl true
  def handle_event("validate", %{"value" => _value}, socket) do
    # Individual input blur - ignore since phx-change handles form validation
    {:noreply, socket}
  end

  @impl true
  def handle_event("apply-range", %{"date_range" => params}, socket) do
    socket = validate_and_update(socket, params)
    {:noreply, socket}
  end

  @impl true
  def handle_event("navigate", %{"direction" => direction}, socket) do
    direction = String.to_existing_atom(direction)
    {:noreply, navigate_range(socket, direction)}
  end

  # Form and validation helpers

  defp assign_form(socket, start_date, end_date) do
    params = %{
      "start_date" => Date.to_iso8601(start_date),
      "end_date" => Date.to_iso8601(end_date)
    }

    form = to_form(params, as: :date_range)

    socket
    |> assign(:form, form)
    |> assign(:start_date, start_date)
    |> assign(:end_date, end_date)
  end

  defp validate_and_update(socket, params) do
    with {:ok, start_date} <- Date.from_iso8601(params["start_date"]),
         {:ok, end_date} <- Date.from_iso8601(params["end_date"]) do
      # Clamp to allowed bounds
      start_date = clamp_date(start_date, socket.assigns.min_date, socket.assigns.max_date)
      end_date = clamp_date(end_date, socket.assigns.min_date, socket.assigns.max_date)

      # Ensure start <= end
      {start_date, end_date} =
        if Date.compare(start_date, end_date) == :gt do
          {end_date, start_date}
        else
          {start_date, end_date}
        end

      # Ensure max range
      end_date =
        if Date.diff(end_date, start_date) > @max_range_days do
          Date.add(start_date, @max_range_days)
        else
          end_date
        end

      socket
      |> assign(:range_type, :custom)
      |> assign_form(start_date, end_date)
      |> update_calendar_data()
    else
      _ -> socket
    end
  end

  defp update_calendar_data(socket) do
    start_date = socket.assigns.start_date
    end_date = socket.assigns.end_date
    days = Date.diff(end_date, start_date) + 1
    dates = Date.range(start_date, end_date) |> Enum.to_list()
    properties = CalendarData.build_properties(start_date, dates)

    socket
    |> assign(:days, days)
    |> assign(:dates, dates)
    |> assign(:properties, properties)
    |> assign(
      :prev_info,
      build_prev_info(socket.assigns.range_type, start_date, socket.assigns.min_date)
    )
    |> assign(
      :next_info,
      build_next_info(socket.assigns.range_type, end_date, socket.assigns.max_date)
    )
  end

  # Range calculation helpers

  defp build_ranges do
    [
      %{value: :this_week, label: dgettext("calendar", "This week")},
      %{value: :next_week, label: dgettext("calendar", "Next week")},
      %{value: :this_month, label: dgettext("calendar", "This month")},
      %{value: :next_month, label: dgettext("calendar", "Next month")},
      %{value: :next_3_months, label: dgettext("calendar", "3 months")},
      %{value: :custom, label: dgettext("calendar", "Custom")}
    ]
  end

  defp calculate_range(:this_week, today) do
    day_of_week = Date.day_of_week(today)
    start_date = Date.add(today, -(day_of_week - 1))
    end_date = Date.add(start_date, 6)
    {start_date, end_date}
  end

  defp calculate_range(:next_week, today) do
    day_of_week = Date.day_of_week(today)
    start_date = Date.add(today, 7 - day_of_week + 1)
    end_date = Date.add(start_date, 6)
    {start_date, end_date}
  end

  defp calculate_range(:this_month, today) do
    start_date = Date.beginning_of_month(today)
    end_date = Date.end_of_month(today)
    {start_date, end_date}
  end

  defp calculate_range(:next_month, today) do
    next_month = today |> Date.end_of_month() |> Date.add(1)
    start_date = Date.beginning_of_month(next_month)
    end_date = Date.end_of_month(next_month)
    {start_date, end_date}
  end

  defp calculate_range(:next_3_months, today) do
    start_date = Date.beginning_of_month(today)
    end_date = today |> Date.add(90) |> Date.end_of_month()
    {start_date, end_date}
  end

  defp calculate_range(:custom, _today) do
    {nil, nil}
  end

  defp navigate_range(socket, direction) do
    range_type = socket.assigns.range_type
    start_date = socket.assigns.start_date
    end_date = socket.assigns.end_date
    min_date = socket.assigns.min_date
    max_date = socket.assigns.max_date

    {new_start, new_end} =
      case range_type do
        type when type in [:this_week, :next_week] ->
          shift = if direction == :prev, do: -7, else: 7
          {Date.add(start_date, shift), Date.add(end_date, shift)}

        type when type in [:this_month, :next_month] ->
          if direction == :prev do
            new_end = Date.add(start_date, -1)
            new_start = Date.beginning_of_month(new_end)
            {new_start, Date.end_of_month(new_end)}
          else
            new_start = Date.add(end_date, 1)
            new_end = Date.end_of_month(new_start)
            {new_start, new_end}
          end

        :next_3_months ->
          if direction == :prev do
            new_end = Date.add(start_date, -1)
            new_start = Date.add(new_end, -89) |> Date.beginning_of_month()
            {new_start, new_end}
          else
            new_start = Date.add(end_date, 1)
            new_end = Date.add(new_start, 89) |> Date.end_of_month()
            {new_start, new_end}
          end

        :custom ->
          days = Date.diff(end_date, start_date)
          shift = if direction == :prev, do: -(days + 1), else: days + 1
          {Date.add(start_date, shift), Date.add(end_date, shift)}
      end

    # Clamp to bounds
    new_start = clamp_date(new_start, min_date, max_date)
    new_end = clamp_date(new_end, min_date, max_date)

    socket
    |> assign_form(new_start, new_end)
    |> update_calendar_data()
  end

  defp build_prev_info(range_type, start_date, min_date) do
    disabled = Date.compare(start_date, min_date) != :gt

    label =
      case range_type do
        type when type in [:this_week, :next_week] ->
          prev_start = Date.add(start_date, -7)
          prev_end = Date.add(start_date, -1)
          format_nav_label(prev_start, prev_end)

        type when type in [:this_month, :next_month, :next_3_months] ->
          prev_month = Date.add(start_date, -1)
          month_name(prev_month.month)

        :custom ->
          prev_start = Date.add(start_date, -7)
          prev_end = Date.add(start_date, -1)
          format_nav_label(prev_start, prev_end)
      end

    %{label: label, disabled: disabled}
  end

  defp build_next_info(range_type, end_date, max_date) do
    disabled = Date.compare(end_date, max_date) != :lt

    label =
      case range_type do
        type when type in [:this_week, :next_week] ->
          next_start = Date.add(end_date, 1)
          next_end = Date.add(end_date, 7)
          format_nav_label(next_start, next_end)

        type when type in [:this_month, :next_month, :next_3_months] ->
          next_month = Date.add(end_date, 1)
          month_name(next_month.month)

        :custom ->
          next_start = Date.add(end_date, 1)
          next_end = Date.add(end_date, 7)
          format_nav_label(next_start, next_end)
      end

    %{label: label, disabled: disabled}
  end

  defp format_nav_label(start_date, end_date) do
    if start_date.month == end_date.month do
      "#{start_date.day}–#{end_date.day} #{month_name_short(start_date.month)}"
    else
      "#{start_date.day} #{month_name_short(start_date.month)}–#{end_date.day} #{month_name_short(end_date.month)}"
    end
  end

  defp month_name(1), do: dgettext("calendar", "January")
  defp month_name(2), do: dgettext("calendar", "February")
  defp month_name(3), do: dgettext("calendar", "March")
  defp month_name(4), do: dgettext("calendar", "April")
  defp month_name(5), do: dgettext("calendar", "May")
  defp month_name(6), do: dgettext("calendar", "June")
  defp month_name(7), do: dgettext("calendar", "July")
  defp month_name(8), do: dgettext("calendar", "August")
  defp month_name(9), do: dgettext("calendar", "September")
  defp month_name(10), do: dgettext("calendar", "October")
  defp month_name(11), do: dgettext("calendar", "November")
  defp month_name(12), do: dgettext("calendar", "December")

  defp month_name_short(1), do: dgettext("calendar", "Jan")
  defp month_name_short(2), do: dgettext("calendar", "Feb")
  defp month_name_short(3), do: dgettext("calendar", "Mar")
  defp month_name_short(4), do: dgettext("calendar", "Apr")
  defp month_name_short(5), do: dgettext("calendar", "May")
  defp month_name_short(6), do: dgettext("calendar", "Jun")
  defp month_name_short(7), do: dgettext("calendar", "Jul")
  defp month_name_short(8), do: dgettext("calendar", "Aug")
  defp month_name_short(9), do: dgettext("calendar", "Sep")
  defp month_name_short(10), do: dgettext("calendar", "Oct")
  defp month_name_short(11), do: dgettext("calendar", "Nov")
  defp month_name_short(12), do: dgettext("calendar", "Dec")

  # Helper functions

  defp dates_with_index(start_date, days) do
    0..(days - 1)
    |> Enum.map(fn offset -> {Date.add(start_date, offset), offset} end)
  end

  defp stats_for_date(_date) do
    [
      %{
        label: dgettext("calendar", "Occupancy"),
        value: "#{Enum.random(50..95)}%",
        variant: :error
      },
      %{
        label: dgettext("calendar", "Arrivals"),
        value: "#{Enum.random(1..5)}",
        variant: :success
      },
      %{
        label: dgettext("calendar", "Departures"),
        value: "#{Enum.random(1..3)}",
        variant: :warning
      },
      %{
        label: dgettext("calendar", "Available"),
        value: "#{Enum.random(2..8)}",
        variant: :neutral
      }
    ]
  end

  defp reservation_position(reservation, grid_start, grid_end) do
    visible_start = max_date(reservation.start_date, grid_start)
    visible_end = min_date(reservation.end_date, grid_end)

    if Date.compare(visible_start, visible_end) == :gt do
      %{start_column: 0, span: 0}
    else
      start_col = Date.diff(visible_start, grid_start) + 1
      span = Date.diff(visible_end, visible_start) + 1
      %{start_column: start_col, span: span}
    end
  end

  defp max_date(d1, d2) do
    if Date.compare(d1, d2) == :gt, do: d1, else: d2
  end

  defp min_date(d1, d2) do
    if Date.compare(d1, d2) == :lt, do: d1, else: d2
  end

  defp clamp_date(date, min_date, max_date) do
    date |> max_date(min_date) |> min_date(max_date)
  end
end
