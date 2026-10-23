import Foundation

// Deterministic sample data for previews, snapshots and checks. No randomness, no network.

extension Place {
    public static let previewCupertino = Place(
        id: "5341145",
        name: "Cupertino",
        region: "California",
        country: "United States",
        coordinate: Coordinate(latitude: 37.323, longitude: -122.03218),
        timeZoneIdentifier: "America/Los_Angeles"
    )

    public static let previewOslo = Place(
        id: "3143244",
        name: "Oslo",
        region: "Oslo",
        country: "Norway",
        coordinate: Coordinate(latitude: 59.91273, longitude: 10.74609),
        timeZoneIdentifier: "Europe/Oslo"
    )

    public static let previewCurrentLocation = Place(
        id: Place.currentLocationID,
        name: "San Francisco",
        region: "California",
        country: "United States",
        coordinate: Coordinate(latitude: 37.77493, longitude: -122.41942),
        timeZoneIdentifier: "America/Los_Angeles"
    )

    public static let previewSearchResults: [Place] = [previewCupertino, previewOslo]
}

extension Forecast {
    /// 2026-10-22 14:00 America/Los_Angeles (21:00 UTC).
    public static let previewReferenceDate = Date(timeIntervalSince1970: 1_792_702_800)

    /// Cupertino, mid-afternoon, partly cloudy. 48 hourly entries from local midnight, 10 days.
    public static let preview: Forecast = makePreview()

    private static func makePreview() -> Forecast {
        let timeZone = TimeZone(identifier: "America/Los_Angeles")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let now = previewReferenceDate
        let today = calendar.startOfDay(for: now)

        let dayConditions: [WeatherCondition] = [
            .partlyCloudy, .clear, .clear, .rainShowers, .rain,
            .overcast, .mainlyClear, .clear, .drizzle, .partlyCloudy,
        ]
        let highs: [Double] = [22, 24, 26, 19, 15, 17, 20, 23, 18, 21]
        let lows: [Double] = [11, 12, 13, 10, 8, 9, 10, 12, 11, 10]

        let daily: [DailyForecast] = (0..<10).map { index in
            let date = calendar.date(byAdding: .day, value: index, to: today)!
            return DailyForecast(
                date: date,
                condition: dayConditions[index],
                highC: highs[index],
                lowC: lows[index],
                precipitationSumMm: [.rain, .rainShowers, .drizzle].contains(dayConditions[index]) ? 4.2 : 0,
                precipitationProbabilityPercent: [.rain, .rainShowers, .drizzle].contains(dayConditions[index]) ? 70 : 5,
                sunrise: date.addingTimeInterval(7 * 3600 + 20 * 60),
                sunset: date.addingTimeInterval(18 * 3600 + 25 * 60),
                uvIndexMax: [.rain, .rainShowers].contains(dayConditions[index]) ? 2 : 5
            )
        }

        let hourly: [HourlyForecast] = (0..<48).map { offset in
            let time = today.addingTimeInterval(Double(offset) * 3600)
            let hourOfDay = offset % 24
            let dayIndex = offset / 24
            let isDaylight = hourOfDay >= 8 && hourOfDay < 18
            // Smooth daily curve: coldest near 05:00, warmest near 15:00.
            let phase = cos(Double(hourOfDay - 15) / 24 * 2 * .pi)
            let low = lows[dayIndex]
            let high = highs[dayIndex]
            let temperature = low + (high - low) * (phase + 1) / 2
            return HourlyForecast(
                time: time,
                temperatureC: (temperature * 10).rounded() / 10,
                condition: isDaylight ? dayConditions[dayIndex] : .mainlyClear,
                isDaylight: isDaylight,
                precipitationProbabilityPercent: dayIndex == 0 ? 10 : 30
            )
        }

        let current = CurrentConditions(
            time: now,
            temperatureC: 21.4,
            apparentTemperatureC: 20.8,
            condition: .partlyCloudy,
            isDaylight: true,
            relativeHumidityPercent: 54,
            windSpeedKmh: 14.2,
            windDirectionDegrees: 300,
            windGustsKmh: 27.5,
            pressureHPa: 1016.4,
            visibilityMeters: 16_000,
            precipitationMm: 0,
            uvIndex: 4.3
        )

        return Forecast(
            coordinate: Place.previewCupertino.coordinate,
            timeZoneIdentifier: timeZone.identifier,
            fetchedAt: now,
            current: current,
            hourly: hourly,
            daily: daily
        )
    }
}
