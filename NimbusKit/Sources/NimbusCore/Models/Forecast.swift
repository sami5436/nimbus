import Foundation

// Canonical units everywhere in the model layer: Celsius, km/h, millimeters, meters, hPa, degrees.
// Conversion to the user's units happens only at presentation time (`WeatherFormatter`),
// so cached forecasts are unit-independent and toggling units never refetches.

/// A full forecast for one coordinate, as returned by `WeatherService` and stored by `ForecastCache`.
public struct Forecast: Sendable, Hashable, Codable {
    public var coordinate: Coordinate
    /// IANA identifier of the location's time zone, e.g. "America/Los_Angeles".
    public var timeZoneIdentifier: String
    /// When this forecast was fetched from the network.
    public var fetchedAt: Date
    public var current: CurrentConditions
    /// Ascending by time, hourly steps, covering at least the next 24 hours from `fetchedAt`.
    public var hourly: [HourlyForecast]
    /// Ascending by date, 10 entries, index 0 is the location's local "today".
    public var daily: [DailyForecast]

    public init(
        coordinate: Coordinate,
        timeZoneIdentifier: String,
        fetchedAt: Date,
        current: CurrentConditions,
        hourly: [HourlyForecast],
        daily: [DailyForecast]
    ) {
        self.coordinate = coordinate
        self.timeZoneIdentifier = timeZoneIdentifier
        self.fetchedAt = fetchedAt
        self.current = current
        self.hourly = hourly
        self.daily = daily
    }

    public var timeZone: TimeZone { TimeZone(identifier: timeZoneIdentifier) ?? .gmt }
}

public struct CurrentConditions: Sendable, Hashable, Codable {
    public var time: Date
    public var temperatureC: Double
    public var apparentTemperatureC: Double
    public var condition: WeatherCondition
    public var isDaylight: Bool
    public var relativeHumidityPercent: Double
    public var windSpeedKmh: Double
    /// Meteorological direction the wind blows FROM, 0 = north, clockwise.
    public var windDirectionDegrees: Double
    public var windGustsKmh: Double?
    public var pressureHPa: Double
    public var visibilityMeters: Double
    public var precipitationMm: Double
    public var uvIndex: Double

    public init(
        time: Date,
        temperatureC: Double,
        apparentTemperatureC: Double,
        condition: WeatherCondition,
        isDaylight: Bool,
        relativeHumidityPercent: Double,
        windSpeedKmh: Double,
        windDirectionDegrees: Double,
        windGustsKmh: Double?,
        pressureHPa: Double,
        visibilityMeters: Double,
        precipitationMm: Double,
        uvIndex: Double
    ) {
        self.time = time
        self.temperatureC = temperatureC
        self.apparentTemperatureC = apparentTemperatureC
        self.condition = condition
        self.isDaylight = isDaylight
        self.relativeHumidityPercent = relativeHumidityPercent
        self.windSpeedKmh = windSpeedKmh
        self.windDirectionDegrees = windDirectionDegrees
        self.windGustsKmh = windGustsKmh
        self.pressureHPa = pressureHPa
        self.visibilityMeters = visibilityMeters
        self.precipitationMm = precipitationMm
        self.uvIndex = uvIndex
    }
}

public struct HourlyForecast: Sendable, Hashable, Codable, Identifiable {
    /// Start of the hour.
    public var time: Date
    public var temperatureC: Double
    public var condition: WeatherCondition
    public var isDaylight: Bool
    public var precipitationProbabilityPercent: Int?

    public init(
        time: Date,
        temperatureC: Double,
        condition: WeatherCondition,
        isDaylight: Bool,
        precipitationProbabilityPercent: Int?
    ) {
        self.time = time
        self.temperatureC = temperatureC
        self.condition = condition
        self.isDaylight = isDaylight
        self.precipitationProbabilityPercent = precipitationProbabilityPercent
    }

    public var id: Date { time }
}

public struct DailyForecast: Sendable, Hashable, Codable, Identifiable {
    /// Local midnight of the day, in the forecast's time zone.
    public var date: Date
    public var condition: WeatherCondition
    public var highC: Double
    public var lowC: Double
    public var precipitationSumMm: Double
    public var precipitationProbabilityPercent: Int?
    /// Nil during polar day or night.
    public var sunrise: Date?
    public var sunset: Date?
    public var uvIndexMax: Double?

    public init(
        date: Date,
        condition: WeatherCondition,
        highC: Double,
        lowC: Double,
        precipitationSumMm: Double,
        precipitationProbabilityPercent: Int?,
        sunrise: Date?,
        sunset: Date?,
        uvIndexMax: Double?
    ) {
        self.date = date
        self.condition = condition
        self.highC = highC
        self.lowC = lowC
        self.precipitationSumMm = precipitationSumMm
        self.precipitationProbabilityPercent = precipitationProbabilityPercent
        self.sunrise = sunrise
        self.sunset = sunset
        self.uvIndexMax = uvIndexMax
    }

    public var id: Date { date }
}
