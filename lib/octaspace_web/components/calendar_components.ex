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
    <calendar-column-hover class="relative block max-h-[calc(100vh-4rem)] overflow-auto">
      <div
        class="min-w-[1100px]"
        style={"--left: #{@left_width}px; --days: #{@days};"}
      >
        <div class="grid grid-cols-[var(--left)_repeat(var(--days),minmax(200px,1fr))]">
          {render_slot(@inner_block)}
        </div>
      </div>
    </calendar-column-hover>
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
    <div
      data-day-col={Date.to_iso8601(@date)}
      class={[
        "p-3  data-[col-hovered]:bg-base-200",
        !@last && "border-r border-base-300"
      ]}
    >
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
    * `:room` - Room map with :name, :capacity, :type, :prices (map of date -> price), and optional :info
    * `:property` - Property map with :name, :icon, :color
    * `:dates` - List of dates to display as columns

  ## Slots
    * `:inner_block` - Reservation cards to render in this row
  """
  attr :room, :map, required: true
  attr :property, :map, default: nil
  attr :dates, :list, required: true
  slot :inner_block

  def room_row(assigns) do
    days = length(assigns.dates)
    assigns = assign(assigns, :days, days)

    ~H"""
    <div class="group col-span-full grid min-h-32 grid-cols-subgrid grid-rows-1 border-b border-base-300">
      <.room_label room={@room} property={@property} />

      <.day_cell
        :for={{date, index} <- Enum.with_index(@dates)}
        date={date}
        day_index={index + 1}
        price={@room[:prices][date]}
        last={index == @days - 1}
      />

      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders the room label cell (sticky left column).
  """
  attr :room, :map, required: true
  attr :property, :map, default: nil

  def room_label(assigns) do
    ~H"""
    <div class="sticky left-0 z-20 border-r border-base-300 bg-base-100 px-4 py-4 group-hover:bg-base-200/60">
      <div class="flex items-center justify-between gap-2">
        <div class="font-semibold">{@room.name}</div>
        <span class="badge badge-outline">{@room.capacity}</span>
      </div>
      <div class="mt-1 text-xs opacity-70">{@room.type}</div>
      <div :if={@room[:info]} class="mt-1 text-xs opacity-70">{@room.info}</div>
      <div :if={@property} class="mt-2">
        <span class={["badge badge-sm gap-1", @property.color]}>
          <.property_icon icon={@property.icon} />
          {@property.name}
        </span>
      </div>
    </div>
    """
  end

  defp property_icon(%{icon: :building} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="size-3">
      <path fill-rule="evenodd" d="M4 16.5v-13h-.25a.75.75 0 0 1 0-1.5h12.5a.75.75 0 0 1 0 1.5H16v13h.25a.75.75 0 0 1 0 1.5h-3.5a.75.75 0 0 1-.75-.75v-2.5a.75.75 0 0 0-.75-.75h-2.5a.75.75 0 0 0-.75.75v2.5a.75.75 0 0 1-.75.75h-3.5a.75.75 0 0 1 0-1.5H4Zm3-11a.5.5 0 0 1 .5-.5h1a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1-.5-.5v-1Zm.5 3.5a.5.5 0 0 0-.5.5v1a.5.5 0 0 0 .5.5h1a.5.5 0 0 0 .5-.5v-1a.5.5 0 0 0-.5-.5h-1Zm3.5-3.5a.5.5 0 0 1 .5-.5h1a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1-.5-.5v-1Zm.5 3.5a.5.5 0 0 0-.5.5v1a.5.5 0 0 0 .5.5h1a.5.5 0 0 0 .5-.5v-1a.5.5 0 0 0-.5-.5h-1Z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp property_icon(%{icon: :home} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="size-3">
      <path fill-rule="evenodd" d="M9.293 2.293a1 1 0 0 1 1.414 0l7 7A1 1 0 0 1 17 11h-1v6a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1v-3a1 1 0 0 0-1-1H9a1 1 0 0 0-1 1v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-6H3a1 1 0 0 1-.707-1.707l7-7Z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp property_icon(%{icon: :tree} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="size-3">
      <path d="M10 2a.75.75 0 0 1 .673.418l6.25 12.5A.75.75 0 0 1 16.25 16H10.75v2.25a.75.75 0 0 1-1.5 0V16H3.75a.75.75 0 0 1-.673-1.082l6.25-12.5A.75.75 0 0 1 10 2Z" />
    </svg>
    """
  end

  defp property_icon(%{icon: :sparkles} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="size-3">
      <path d="M10 1a.75.75 0 0 1 .75.75v1.5a.75.75 0 0 1-1.5 0v-1.5A.75.75 0 0 1 10 1ZM5.05 3.05a.75.75 0 0 1 1.06 0l1.062 1.06A.75.75 0 1 1 6.11 5.173L5.05 4.11a.75.75 0 0 1 0-1.06ZM14.95 3.05a.75.75 0 0 1 0 1.06l-1.06 1.062a.75.75 0 0 1-1.062-1.061l1.061-1.06a.75.75 0 0 1 1.06 0ZM3 8a.75.75 0 0 1 .75-.75h1.5a.75.75 0 0 1 0 1.5h-1.5A.75.75 0 0 1 3 8ZM14 8a.75.75 0 0 1 .75-.75h1.5a.75.75 0 0 1 0 1.5h-1.5A.75.75 0 0 1 14 8ZM7.172 13.828a.75.75 0 0 1-1.061-1.06l1.06-1.062a.75.75 0 0 1 1.062 1.061l-1.06 1.06ZM10.766 10.766a.75.75 0 0 1 0 1.061l-1.06 1.06a.75.75 0 1 1-1.062-1.06l1.061-1.06a.75.75 0 0 1 1.06 0ZM10 14a.75.75 0 0 1 .75.75v1.5a.75.75 0 0 1-1.5 0v-1.5A.75.75 0 0 1 10 14Z" />
    </svg>
    """
  end

  defp property_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="size-3">
      <path fill-rule="evenodd" d="M4 16.5v-13h-.25a.75.75 0 0 1 0-1.5h12.5a.75.75 0 0 1 0 1.5H16v13h.25a.75.75 0 0 1 0 1.5h-3.5a.75.75 0 0 1-.75-.75v-2.5a.75.75 0 0 0-.75-.75h-2.5a.75.75 0 0 0-.75.75v2.5a.75.75 0 0 1-.75.75h-3.5a.75.75 0 0 1 0-1.5H4Z" clip-rule="evenodd" />
    </svg>
    """
  end

  @doc """
  Renders a single day cell background.
  """
  attr :date, Date, required: true
  attr :day_index, :integer, required: true
  attr :price, :integer, default: nil
  attr :last, :boolean, default: false

  def day_cell(assigns) do
    ~H"""
    <div
      data-day-col={Date.to_iso8601(@date)}
      style={"--start-at: #{@day_index + 1};"}
      class={[
        "relative col-start-[var(--start-at)] row-span-full",
        "group-hover:bg-base-200 data-[hover-current]:bg-base-300 data-[col-hovered]:bg-base-200",
        !@last && "border-r border-base-300"
      ]}
    >
      <div class="flex h-full flex-col p-2">
        <div class="flex items-start justify-between text-xs opacity-70">
          <span>{format_day(@date)}</span>
          <span :if={@price}>{@price}€</span>
        </div>
      </div>
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
        class={[
          "rounded-btn w-full border p-2 text-left shadow-sm",
          "hover:shadow-md focus:outline-none focus-visible:ring focus-visible:ring-primary/30",
          status_card_class(@reservation.status)
        ]}
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

  defp status_card_class(:paid), do: "bg-success/10 border-success/30 hover:border-success/50"
  defp status_card_class(:pending), do: "bg-warning/10 border-warning/30 hover:border-warning/50"
  defp status_card_class(:cancelled), do: "bg-error/10 border-error/30 hover:border-error/50"
  defp status_card_class(_), do: "bg-base-100 border-base-300 hover:border-base-content/20"

  defp format_status(:paid), do: "Paid"
  defp format_status(:pending), do: "Pending"
  defp format_status(:cancelled), do: "Cancelled"
  defp format_status(status), do: status |> to_string() |> String.capitalize()

  defp format_reservation_dates(%{start_date: start_date, end_date: end_date}) do
    "#{start_date.day}–#{end_date.day} #{month_name_lt(start_date.month)}"
  end
end
