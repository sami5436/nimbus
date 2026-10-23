import SwiftUI
import NimbusCore

/// One place's weather over a condition-aware sky: header, hourly strip, 10-day list, detail tiles.
public struct WeatherScreen: View {
    @State private var viewModel: WeatherViewModel
    @Environment(\.isSnapshot) private var isSnapshot
    private let settings: SettingsModel
    private let now: @Sendable () -> Date

    public init(viewModel: WeatherViewModel, settings: SettingsModel, now: @escaping @Sendable () -> Date) {
        _viewModel = State(initialValue: viewModel)
        self.settings = settings
        self.now = now
    }

    public init(place: Place, dependencies: AppDependencies, settings: SettingsModel) {
        self.init(
            viewModel: WeatherViewModel(place: place, dependencies: dependencies),
            settings: settings,
            now: dependencies.now
        )
    }

    public var body: some View {
        ZStack {
            SkyBackground(theme: theme).ignoresSafeArea()
            content
        }
        .task { await viewModel.load() }
    }

    private var theme: SkyTheme {
        switch viewModel.state {
        case .loaded(let forecast, _):
            SkyTheme(condition: forecast.current.condition, isDaylight: forecast.isDaylight(at: now()))
        case .loading, .failed:
            .cloudyDay
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            LoadingStateView()
        case .failed(let error):
            ErrorStateView(error: error) { Task { await viewModel.retry() } }
        case .loaded(let forecast, let freshness):
            loadedContent(forecast, freshness)
        }
    }

    private func loadedContent(_ forecast: Forecast, _ freshness: WeatherViewModel.Freshness) -> some View {
        let formatter = settings.formatter
        let date = now()
        let stack = VStack(spacing: 16) {
            if freshness == .offline {
                OfflineBanner(text: "Offline. Updated \(formatter.clockTime(forecast.fetchedAt, timeZone: forecast.timeZone))")
            }
            CurrentConditionsHeader(
                placeName: viewModel.place.name,
                current: forecast.current,
                today: forecast.day(containing: date),
                formatter: formatter
            )
            HourlyForecastStrip(
                hours: forecast.hours(from: date, count: 24),
                timeZone: forecast.timeZone,
                now: date,
                formatter: formatter
            )
            DailyForecastList(
                days: forecast.daily,
                timeZone: forecast.timeZone,
                now: date,
                currentTemperatureC: forecast.current.temperatureC,
                formatter: formatter
            )
            DetailTilesGrid(forecast: forecast, now: date, formatter: formatter)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)

        return Group {
            if isSnapshot {
                stack.frame(maxHeight: .infinity, alignment: .top)
            } else {
                ScrollView { stack }.refreshable { await viewModel.refresh() }
            }
        }
        .foregroundStyle(.white)
    }
}
