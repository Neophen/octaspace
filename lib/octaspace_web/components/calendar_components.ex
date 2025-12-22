defmodule OctaspaceWeb.CalendarUI do
  @moduledoc """
  Calendar grid components for displaying room reservations.
  """
  use Phoenix.Component

  @doc """
  Renders the main calendar grid container.

  ## Attributes
    * `:days` - Number of days to display (default: 7)
    * `:left_width` - Width of the left column in pixels (default: 240)

  ## Slots
    * `:inner_block` - The calendar content (header + room rows)
  """
  attr :days, :integer, default: 7
  attr :left_width, :integer, default: 240
  slot :inner_block, required: true

  def grid(assigns) do
    ~H"""
    <div class="relative overflow-auto">
      <div
        class="min-w-[1100px]"
        style={"--left: #{@left_width}px; --days: #{@days};"}
      >
        <div class="grid grid-cols-[var(--left)_repeat(var(--days),minmax(200px,1fr))]">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the calendar header row.

  ## Slots
    * `:corner` - Content for the top-left corner cell
    * `:inner_block` - Day header cells
  """
  slot :corner, required: true
  slot :inner_block, required: true

  def header(assigns) do
    ~H"""
    <div class="sticky top-0 z-30 [grid-column:1/-1] grid grid-cols-subgrid border-b border-base-300 bg-base-100">
      <div class="sticky left-0 z-40 border-r border-base-300 bg-base-100 px-4 py-3">
        {render_slot(@corner)}
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a single day header cell with date and stats.

  ## Attributes
    * `:date` - The date to display
    * `:month` - Month name
    * `:year` - Year
    * `:day_name` - Day of week abbreviation
    * `:stats` - List of stat maps with :label, :value, and :variant keys
    * `:last` - Whether this is the last day (no right border)
  """
  attr :date, Date, required: true
  attr :stats, :list, default: []
  attr :last, :boolean, default: false

  def day_header(assigns) do
    ~H"""
    <div class={["p-3", !@last && "border-r border-base-300"]}>
      <div class="text-xs opacity-70">{format_month_year(@date)}</div>
      <div class="text-xs font-bold">{format_day(@date)}</div>

      <div :if={@stats != []} class="mt-2 flex flex-wrap gap-2">
        <div :for={stat <- @stats} class="grid gap-1">
          <span class="text-xs opacity-70">{stat.label}</span>
          <span class={["badge badge-xs", stat_badge_class(stat.variant)]}>{stat.value}</span>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a room row with day cells and reservations.

  ## Attributes
    * `:room` - Room map with :name, :capacity, :type, and optional :info
    * `:days` - Number of days in the grid

  ## Slots
    * `:inner_block` - Reservation cards to render in this row
  """
  attr :room, :map, required: true
  attr :days, :integer, required: true
  slot :inner_block

  def room_row(assigns) do
    ~H"""
    <div class="group col-span-full grid min-h-32 grid-cols-subgrid grid-rows-1 border-b border-base-300">
      <.room_label room={@room} />

      <.day_cell :for={day_index <- 1..@days} day_index={day_index} last={day_index == @days} />

      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders the room label cell (sticky left column).
  """
  attr :room, :map, required: true

  def room_label(assigns) do
    ~H"""
    <div class="sticky left-0 z-20 border-r border-base-300 bg-base-100 px-4 py-4 group-hover:bg-base-200/60">
      <div class="flex items-center justify-between gap-2">
        <div class="font-semibold">{@room.name}</div>
        <span class="badge badge-outline">{@room.capacity}</span>
      </div>
      <div class="mt-1 text-xs opacity-70">{@room.type}</div>
      <div :if={@room[:info]} class="mt-1 text-xs opacity-70">{@room.info}</div>
    </div>
    """
  end

  @doc """
  Renders a single day cell background.
  """
  attr :day_index, :integer, required: true
  attr :last, :boolean, default: false

  def day_cell(assigns) do
    ~H"""
    <div
      style={"--start-at: #{@day_index + 1};"}
      class={[
        "relative col-start-[var(--start-at)] row-span-full group-hover:bg-base-200/40 hover:bg-base-300",
        !@last && "border-r border-base-300"
      ]}
    >
      <div class="h-full"></div>
    </div>
    """
  end

  @doc """
  Renders a reservation card that spans multiple days.

  ## Attributes
    * `:reservation` - Reservation map with :guest_name, :start_date, :end_date, :guests, :status, :tags
    * `:start_column` - Grid column where reservation starts (1-indexed, add 1 for room label offset)
    * `:span` - Number of days the reservation spans
  """
  attr :reservation, :map, required: true
  attr :start_column, :integer, required: true
  attr :span, :integer, required: true

  def reservation_card(assigns) do
    ~H"""
    <div
      class="z-10 row-span-full mt-auto h-max overflow-hidden"
      style={"grid-column: #{@start_column + 1} / span #{@span};"}
    >
      <button
        type="button"
        class="rounded-btn w-full border border-base-300 bg-base-100 p-2 text-left shadow-sm hover:border-base-content/20 hover:shadow-md focus:outline-none focus-visible:ring focus-visible:ring-primary/30"
      >
        <div class="flex items-start justify-between gap-2">
          <div class="min-w-0">
            <div class="truncate text-xs font-semibold">{@reservation.guest_name}</div>
            <div class="mt-0.5 text-[11px] opacity-70">
              {format_reservation_dates(@reservation)} · {@reservation.nights} nights · {@reservation.guests} guests
            </div>
          </div>
          <span class={["badge shrink-0 badge-xs", status_badge_class(@reservation.status)]}>
            {format_status(@reservation.status)}
          </span>
        </div>

        <div :if={@reservation[:tags] && @reservation.tags != []} class="mt-2 flex flex-wrap gap-1.5">
          <span :for={tag <- @reservation.tags} class="badge badge-ghost badge-xs">{tag}</span>
        </div>
      </button>
    </div>
    """
  end

  # Helper functions

  defp format_month_year(date) do
    month_name = month_name_lt(date.month)
    "#{month_name} #{date.year}"
  end

  defp format_day(date) do
    day_name = day_name_lt(Date.day_of_week(date))
    "#{date.day} - #{day_name}"
  end

  defp month_name_lt(1), do: "Sausis"
  defp month_name_lt(2), do: "Vasaris"
  defp month_name_lt(3), do: "Kovas"
  defp month_name_lt(4), do: "Balandis"
  defp month_name_lt(5), do: "Gegužė"
  defp month_name_lt(6), do: "Birželis"
  defp month_name_lt(7), do: "Liepa"
  defp month_name_lt(8), do: "Rugpjūtis"
  defp month_name_lt(9), do: "Rugsėjis"
  defp month_name_lt(10), do: "Spalis"
  defp month_name_lt(11), do: "Lapkritis"
  defp month_name_lt(12), do: "Gruodis"

  defp day_name_lt(1), do: "Pir"
  defp day_name_lt(2), do: "Ant"
  defp day_name_lt(3), do: "Tre"
  defp day_name_lt(4), do: "Ket"
  defp day_name_lt(5), do: "Pen"
  defp day_name_lt(6), do: "Šeš"
  defp day_name_lt(7), do: "Sek"

  defp stat_badge_class(:error), do: "badge-error"
  defp stat_badge_class(:success), do: "badge-success"
  defp stat_badge_class(:warning), do: "badge-warning"
  defp stat_badge_class(:neutral), do: "badge-neutral"
  defp stat_badge_class(_), do: "badge-neutral"

  defp status_badge_class(:paid), do: "badge-success"
  defp status_badge_class(:pending), do: "badge-warning"
  defp status_badge_class(:cancelled), do: "badge-error"
  defp status_badge_class(_), do: "badge-neutral"

  defp format_status(:paid), do: "Paid"
  defp format_status(:pending), do: "Pending"
  defp format_status(:cancelled), do: "Cancelled"
  defp format_status(status), do: status |> to_string() |> String.capitalize()

  defp format_reservation_dates(%{start_date: start_date, end_date: end_date}) do
    "#{start_date.day}–#{end_date.day} #{month_name_lt(start_date.month)}"
  end
end
