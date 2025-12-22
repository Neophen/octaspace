defmodule OctaspaceWeb.CalendarLive do
  use OctaspaceWeb, :live_view

  alias OctaspaceWeb.CalendarUI

  @impl true
  def mount(_params, _session, socket) do
    # Mock data
    start_date = ~D[2026-01-14]
    end_date = ~D[2026-03-20]
    days = Date.diff(end_date, start_date) + 1

    properties = build_mock_properties(start_date)

    socket =
      socket
      |> assign(:start_date, start_date)
      |> assign(:end_date, end_date)
      |> assign(:days, days)
      |> assign(:properties, properties)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <CalendarUI.grid days={@days}>
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
          last={index == @days - 1}
        />
      </CalendarUI.header>

      <%= for property <- @properties do %>
        <CalendarUI.room_row :for={room <- property.rooms} room={room} days={@days}>
          <CalendarUI.reservation_card
            :for={reservation <- room.reservations}
            reservation={reservation}
            {reservation_position(reservation, @start_date, @end_date)}
          />
        </CalendarUI.room_row>
      <% end %>
    </CalendarUI.grid>
    """
  end

  # Helper functions

  defp dates_with_index(start_date, days) do
    0..(days - 1)
    |> Enum.map(fn offset -> {Date.add(start_date, offset), offset} end)
  end

  defp stats_for_date(_date) do
    # Mock stats - in real app, calculate from reservations
    [
      %{label: "Užimtumas", value: "#{Enum.random(50..95)}%", variant: :error},
      %{label: "Atvyksta", value: "#{Enum.random(1..5)}", variant: :success},
      %{label: "Išvyksta", value: "#{Enum.random(1..3)}", variant: :warning},
      %{label: "Laisvi", value: "#{Enum.random(2..8)}", variant: :neutral}
    ]
  end

  defp reservation_position(reservation, grid_start, grid_end) do
    # Calculate the visible portion of the reservation within the grid
    visible_start = max_date(reservation.start_date, grid_start)
    visible_end = min_date(reservation.end_date, grid_end)

    if Date.compare(visible_start, visible_end) == :gt do
      # Reservation is outside the visible range
      %{start_column: 0, span: 0}
    else
      # Column is 1-indexed, +1 for room label column offset
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

  # Mock data builders

  defp build_mock_properties(start_date) do
    [
      %{
        id: 1,
        name: "Seaside Hotel",
        rooms: [
          %{
            id: 1,
            name: "Kambarys 101",
            capacity: 2,
            type: "Standard",
            info: "Sea view",
            reservations: [
              %{
                id: 1,
                guest_name: "Jonas K.",
                start_date: start_date,
                end_date: Date.add(start_date, 2),
                nights: 2,
                guests: 2,
                status: :paid,
                tags: ["STD", "Late check-in"]
              }
            ]
          },
          %{
            id: 2,
            name: "Kambarys 102",
            capacity: 4,
            type: "Family",
            info: "Garden view",
            reservations: [
              %{
                id: 2,
                guest_name: "Petras M.",
                start_date: Date.add(start_date, 1),
                end_date: Date.add(start_date, 4),
                nights: 3,
                guests: 4,
                status: :pending,
                tags: ["FAM", "Extra bed"]
              }
            ]
          },
          %{
            id: 3,
            name: "Kambarys 103",
            capacity: 2,
            type: "Deluxe",
            reservations: [
              %{
                id: 3,
                guest_name: "Ona S.",
                start_date: Date.add(start_date, 3),
                end_date: Date.add(start_date, 5),
                nights: 2,
                guests: 1,
                status: :paid,
                tags: ["DLX"]
              },
              %{
                id: 4,
                guest_name: "Marija L.",
                start_date: Date.add(start_date, -2),
                end_date: Date.add(start_date, 1),
                nights: 3,
                guests: 2,
                status: :paid,
                tags: ["STD"]
              }
            ]
          },
          %{
            id: 4,
            name: "Kambarys 104",
            capacity: 6,
            type: "Suite",
            info: "Top floor",
            reservations: []
          },
          %{
            id: 5,
            name: "Kambarys 105",
            capacity: 2,
            type: "Standard",
            reservations: [
              %{
                id: 5,
                guest_name: "Tomas V.",
                start_date: Date.add(start_date, 5),
                end_date: Date.add(start_date, 8),
                nights: 3,
                guests: 2,
                status: :pending,
                tags: ["STD", "Breakfast included"]
              }
            ]
          }
        ]
      }
    ]
  end
end
