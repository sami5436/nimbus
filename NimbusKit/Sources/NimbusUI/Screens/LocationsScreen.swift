import SwiftUI
import NimbusCore

/// Saved places as mini weather cards, with search and a units menu.
public struct LocationsScreen: View {
    private let viewModel: LocationsViewModel
    private let settings: SettingsModel
    private let onSelect: (Place) -> Void

    public init(viewModel: LocationsViewModel, settings: SettingsModel, onSelect: @escaping (Place) -> Void) {
        self.viewModel = viewModel
        self.settings = settings
        self.onSelect = onSelect
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Weather")
                .searchable(
                    text: Binding(get: { viewModel.query }, set: { viewModel.updateQuery($0) }),
                    prompt: "Search for a city"
                )
                .toolbar {
                    ToolbarItem(placement: .primaryAction) { unitsMenu }
                    #if os(iOS)
                    ToolbarItem(placement: .topBarLeading) {
                        if !viewModel.places.isEmpty { EditButton() }
                    }
                    #endif
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isSearching {
            searchResults
        } else if viewModel.isEmpty {
            MessageStateView(
                symbol: "mappin.and.ellipse",
                title: "No Cities Yet",
                message: viewModel.currentLocationError?.displayMessage ?? "Search for a city to see its weather."
            )
            .background(SkyBackground(theme: .cloudyDay).ignoresSafeArea())
        } else if !viewModel.hasLoaded {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            placeList
        }
    }

    private var placeList: some View {
        let formatter = settings.formatter
        return List {
            if let current = viewModel.currentPlace {
                Section {
                    row(current, formatter: formatter, title: "My Location")
                }
            } else if let error = viewModel.currentLocationError {
                Section {
                    Label(error.displayMessage, systemImage: error.symbolName)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                ForEach(viewModel.places) { place in
                    row(place, formatter: formatter, title: place.name)
                }
                .onDelete { offsets in Task { await viewModel.delete(at: offsets) } }
                .onMove { source, destination in Task { await viewModel.move(from: source, to: destination) } }
            }
        }
        .listStyle(.plain)
    }

    private func row(_ place: Place, formatter: WeatherFormatter, title: String) -> some View {
        Button { onSelect(place) } label: {
            PlaceCard(title: title, subtitle: place.isCurrentLocation ? place.name : subtitle(place),
                      summary: viewModel.summaries[place.id], formatter: formatter)
        }
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func subtitle(_ place: Place) -> String {
        [place.region, place.country].compactMap { $0 }.joined(separator: ", ")
    }

    @ViewBuilder
    private var searchResults: some View {
        switch viewModel.searchState {
        case .idle, .searching:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            MessageStateView(symbol: "magnifyingglass", title: "No Results",
                             message: "No cities match \"\(viewModel.query)\".")
                .background(SkyBackground(theme: .cloudyDay).ignoresSafeArea())
        case .failed(let error):
            MessageStateView(symbol: error.symbolName, title: error.displayTitle, message: error.displayMessage,
                             actionTitle: "Try Again") { Task { await viewModel.performSearch() } }
                .background(SkyBackground(theme: .cloudyDay).ignoresSafeArea())
        case .results(let results):
            List(results) { place in
                Button {
                    Task {
                        await viewModel.add(place)
                        onSelect(place)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(place.name).font(.headline)
                        Text(subtitle(place)).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
    }

    private var unitsMenu: some View {
        Menu {
            Picker("Temperature", selection: Binding(
                get: { settings.preferences.temperature },
                set: { unit in Task { await settings.setTemperature(unit) } }
            )) {
                Text("Fahrenheit").tag(TemperatureUnit.fahrenheit)
                Text("Celsius").tag(TemperatureUnit.celsius)
            }
            Picker("Wind", selection: Binding(
                get: { settings.preferences.speed },
                set: { unit in Task { await settings.setSpeed(unit) } }
            )) {
                Text("Miles per hour").tag(SpeedUnit.milesPerHour)
                Text("Kilometers per hour").tag(SpeedUnit.kilometersPerHour)
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

/// Rounded card tinted by the place's sky theme: name and condition left, temperature and range right.
struct PlaceCard: View {
    let title: String
    let subtitle: String
    let summary: PlaceSummary?
    let formatter: WeatherFormatter

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title3.weight(.semibold))
                Text(subtitle).font(.footnote).opacity(0.85)
                Spacer(minLength: 8)
                Text(summary?.condition.displayName ?? " ").font(.footnote)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(summary.map { formatter.temperature($0.temperatureC) } ?? "--°")
                    .font(.system(size: 44, weight: .light))
                Spacer(minLength: 8)
                if let high = summary?.highC, let low = summary?.lowC {
                    Text("H:\(formatter.temperature(high)) L:\(formatter.temperature(low))").font(.footnote)
                }
            }
        }
        .foregroundStyle(.white)
        .padding(14)
        .frame(minHeight: 100)
        .background(
            SkyBackground(theme: theme).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        )
    }

    private var theme: SkyTheme {
        summary.map { SkyTheme(condition: $0.condition, isDaylight: $0.isDaylight) } ?? .cloudyDay
    }
}
