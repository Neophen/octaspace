defmodule Octaspace.Mock.CalendarData do
  @moduledoc """
  Mock data for calendar development and testing.
  """

  def build_properties(start_date, dates) do
    [
      %{
        id: 1,
        name: "Seaside",
        icon: :building,
        color: "badge-primary",
        rooms: [
          build_room(1, "Kambarys 101", 2, "Standard", "Sea view", dates, 60, [
            build_reservation(1, "Jonas K.", start_date, 2, 2, :paid, ["STD", "Late check-in"])
          ]),
          build_room(2, "Kambarys 102", 4, "Family", "Garden view", dates, 85, [
            build_reservation(2, "Petras M.", Date.add(start_date, 1), 3, 4, :pending, ["FAM", "Extra bed"])
          ]),
          build_room(3, "Kambarys 103", 2, "Deluxe", nil, dates, 120, [
            build_reservation(3, "Ona S.", Date.add(start_date, 3), 2, 1, :paid, ["DLX"]),
            build_reservation(4, "Marija L.", Date.add(start_date, -2), 3, 2, :paid, ["STD"])
          ]),
          build_room(4, "Kambarys 104", 6, "Suite", "Top floor", dates, 200, []),
          build_room(5, "Kambarys 105", 2, "Standard", nil, dates, 55, [
            build_reservation(5, "Tomas V.", Date.add(start_date, 5), 3, 2, :pending, ["STD", "Breakfast"])
          ]),
          build_room(6, "Kambarys 106", 2, "Standard", "Pool view", dates, 65, [])
        ]
      },
      %{
        id: 2,
        name: "Mountain Lodge",
        icon: :tree,
        color: "badge-success",
        rooms: [
          build_room(7, "Cabin A", 4, "Rustic", "Fireplace", dates, 95, [
            build_reservation(6, "Andrius K.", Date.add(start_date, 2), 4, 3, :paid, ["RST"])
          ]),
          build_room(8, "Cabin B", 4, "Rustic", "Mountain view", dates, 95, []),
          build_room(9, "Cabin C", 6, "Family", "Hot tub", dates, 140, [
            build_reservation(7, "Giedrius P.", Date.add(start_date, 0), 5, 5, :paid, ["FAM", "Hot tub"])
          ]),
          build_room(10, "Cabin D", 2, "Cozy", nil, dates, 70, [
            build_reservation(8, "Laura M.", Date.add(start_date, 4), 2, 2, :pending, ["COZ"])
          ]),
          build_room(11, "Cabin E", 8, "Grand", "Sauna", dates, 180, [])
        ]
      },
      %{
        id: 3,
        name: "City Center",
        icon: :sparkles,
        color: "badge-warning",
        rooms: [
          build_room(12, "Suite 1A", 2, "Business", "City view", dates, 110, [
            build_reservation(9, "Viktoras S.", Date.add(start_date, 1), 2, 1, :paid, ["BIZ"])
          ]),
          build_room(13, "Suite 1B", 2, "Business", nil, dates, 100, []),
          build_room(14, "Suite 2A", 4, "Executive", "Corner unit", dates, 150, [
            build_reservation(10, "Rasa D.", Date.add(start_date, 3), 3, 2, :pending, ["EXE", "Late checkout"])
          ]),
          build_room(15, "Suite 2B", 2, "Standard", nil, dates, 75, [
            build_reservation(11, "Domas R.", Date.add(start_date, 6), 2, 2, :paid, ["STD"])
          ]),
          build_room(16, "Penthouse", 6, "Luxury", "Rooftop terrace", dates, 300, [])
        ]
      },
      %{
        id: 4,
        name: "Countryside",
        icon: :home,
        color: "badge-error",
        rooms: [
          build_room(17, "Farmhouse 1", 6, "Traditional", "Garden", dates, 85, [
            build_reservation(12, "Aurimas V.", Date.add(start_date, 0), 4, 4, :paid, ["TRD", "Breakfast"])
          ]),
          build_room(18, "Farmhouse 2", 4, "Traditional", nil, dates, 75, []),
          build_room(19, "Barn Loft", 2, "Romantic", "Skylight", dates, 90, [
            build_reservation(13, "Egle K.", Date.add(start_date, 2), 3, 2, :paid, ["ROM"])
          ]),
          build_room(20, "Garden Cottage", 3, "Cozy", "Private patio", dates, 80, [
            build_reservation(14, "Mantas B.", Date.add(start_date, 5), 2, 2, :pending, ["COZ"])
          ])
        ]
      }
    ]
  end

  defp build_room(id, name, capacity, type, info, dates, base_price, reservations) do
    %{
      id: id,
      name: name,
      capacity: capacity,
      type: type,
      info: info,
      prices: generate_prices(dates, base_price),
      reservations: reservations
    }
  end

  defp build_reservation(id, guest_name, start_date, nights, guests, status, tags) do
    %{
      id: id,
      guest_name: guest_name,
      start_date: start_date,
      end_date: Date.add(start_date, nights),
      nights: nights,
      guests: guests,
      status: status,
      tags: tags
    }
  end

  defp generate_prices(dates, base_price) do
    dates
    |> Enum.map(fn date ->
      day_of_week = Date.day_of_week(date)
      price = if day_of_week in [6, 7], do: base_price + 20, else: base_price
      {date, price}
    end)
    |> Map.new()
  end
end
