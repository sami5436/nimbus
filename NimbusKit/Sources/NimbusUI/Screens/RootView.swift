import SwiftUI
import NimbusCore

/// App root: pages through current location + saved places, opens the locations list and search.
/// Owns the view models; the app target only constructs this with live `AppDependencies`.
public struct RootView: View {
    private let dependencies: AppDependencies
    @State private var locations: LocationsViewModel
    @State private var settings: SettingsModel
    @State private var selection: String?
    @State private var showingLocations = false

    public init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _locations = State(initialValue: LocationsViewModel(dependencies: dependencies))
        _settings = State(initialValue: SettingsModel(dependencies: dependencies))
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            pager
            bottomBar
        }
        .task {
            await settings.load()
            await locations.load()
        }
        .onChange(of: showingLocations) { _, isShowing in
            if isShowing { Task { await locations.loadSummaries() } }
        }
        .sheet(isPresented: $showingLocations) {
            LocationsScreen(viewModel: locations, settings: settings) { place in
                selection = place.id
                showingLocations = false
            }
        }
    }

    private var selectedID: Binding<String?> {
        Binding(
            get: {
                let ids = locations.displayPlaces.map(\.id)
                if let selection, ids.contains(selection) { return selection }
                return ids.first
            },
            set: { selection = $0 }
        )
    }

    @ViewBuilder
    private var pager: some View {
        if !locations.hasLoaded || locations.isResolvingLocation && locations.displayPlaces.isEmpty {
            ZStack {
                SkyBackground(theme: .cloudyDay).ignoresSafeArea()
                LoadingStateView()
            }
        } else if locations.isEmpty {
            ZStack {
                SkyBackground(theme: .cloudyDay).ignoresSafeArea()
                MessageStateView(
                    symbol: "cloud.sun",
                    title: "Welcome to Nimbus",
                    message: locations.currentLocationError?.displayMessage ?? "Add a city to see its forecast.",
                    actionTitle: "Add a City"
                ) { showingLocations = true }
            }
        } else {
            #if os(iOS)
            TabView(selection: selectedID) {
                ForEach(locations.displayPlaces) { place in
                    WeatherScreen(place: place, dependencies: dependencies, settings: settings)
                        .tag(Optional(place.id))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            #else
            if let place = locations.displayPlaces.first(where: { $0.id == selectedID.wrappedValue }) {
                WeatherScreen(place: place, dependencies: dependencies, settings: settings)
                    .id(place.id)
            }
            #endif
        }
    }

    private var bottomBar: some View {
        HStack {
            Spacer()
            Button { showingLocations = true } label: {
                Image(systemName: "list.bullet")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Locations")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}
