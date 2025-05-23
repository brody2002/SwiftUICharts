//
//  MultiLineChart.swift
//  
//
//  Created by Will Dale on 23/01/2021.
//

import SwiftUI

/**
 View for drawing a multi-line, line chart.
 
 Uses `MultiLineChartData` data model.
 
 # Declaration
 
 ```
 MultiLineChart(chartData: data)
 ```
 
 # View Modifiers
 
 The order of the view modifiers is some what important
 as the modifiers are various types for stacks that wrap
 around the previous views.
 ```
 .touchOverlay(chartData: data)
 .pointMarkers(chartData: data)
 .averageLine(chartData: data,
              strokeStyle: StrokeStyle(lineWidth: 3, dash: [5,10]))
 .yAxisPOI(chartData: data,
           markerName: "50",
           markerValue: 50,
           lineColour: Color.blue,
           strokeStyle: StrokeStyle(lineWidth: 3, dash: [5,10]))
 .xAxisGrid(chartData: data)
 .yAxisGrid(chartData: data)
 .xAxisLabels(chartData: data)
 .yAxisLabels(chartData: data)
 .infoBox(chartData: data)
 .floatingInfoBox(chartData: data)
 .headerBox(chartData: data)
 .legends(chartData: data)
 ```
 */
public struct MultiLineChart<ChartData>: View where ChartData: MultiLineChartData {
    
    @ObservedObject private var chartData: ChartData
    @State private var timer: Timer?
    
    private let minValue: Double
    private let range: Double
    private let isFilled: Bool
    
    /// Initialises a multi-line, line chart.
    /// - Parameter chartData: Must be MultiLineChartData model.
    public init(chartData: ChartData, isSegmented: Bool) {
        self.chartData = chartData
        self.minValue = chartData.minValue
        self.range = chartData.range
        self.isFilled = chartData.isFilled
    }

    public var body: some View {
        GeometryReader { geo in
            if chartData.isGreaterThanTwo() {
                ZStack {
                    chartData.getAccessibility()
                    ForEach(chartData.dataSets.dataSets, id: \.id) { dataSet in
                        if isFilled {
                            ZStack {
                                MultiLineChartCell(chartData: chartData, dataSet: dataSet, minValue: minValue, range: range, isFilled: true)
                                    .animation(.none)
                                MultiLineChartCell(chartData: chartData, dataSet: dataSet, minValue: minValue, range: range, isFilled: false)
                            }
                        } else {
                            MultiLineChartCell(chartData: chartData, dataSet: dataSet, minValue: minValue, range: range, isFilled: false)
                        }
                    }
                }
                // Needed for axes label frames
                .onAppear {
                    self.chartData.viewData.chartSize = geo.frame(in: .local)
                }
                .layoutNotifier(timer)
            } else {
                CustomNoDataView(chartData: chartData)
            }
        }
    }
}

fileprivate struct MultiLineChartCell<ChartData>: View where ChartData: MultiLineChartData {
    @ObservedObject var chartData: ChartData
    let dataSet: LineDataSet
    let minValue: Double
    let range: Double
    let isFilled: Bool
    
    var body: some View {
        if dataSet.style.lineColour.colourType == .colour,
           let colour = dataSet.style.lineColour.colour
        {
            LineChartColourSubView(chartData: chartData,
                                   dataSet: dataSet,
                                   minValue: minValue,
                                   range: range,
                                   colour: isFilled ? colour : dataSet.style.strokeColor ?? colour,
                                   isFilled: isFilled)
        } else if dataSet.style.lineColour.colourType == .gradientColour,
                  let colours = dataSet.style.lineColour.colours,
                  let startPoint = dataSet.style.lineColour.startPoint,
                  let endPoint = dataSet.style.lineColour.endPoint
        {
            LineChartColoursSubView(chartData: chartData,
                                    dataSet: dataSet,
                                    minValue: minValue,
                                    range: range,
                                    colours: colours,
                                    startPoint: startPoint,
                                    endPoint: endPoint,
                                    isFilled: false)
        } else if dataSet.style.lineColour.colourType == .gradientStops,
                  let stops = dataSet.style.lineColour.stops,
                  let startPoint = dataSet.style.lineColour.startPoint,
                  let endPoint = dataSet.style.lineColour.endPoint
        {
            LineChartStopsSubView(chartData: chartData,
                                  dataSet: dataSet,
                                  minValue: minValue,
                                  range: range,
                                  stops: GradientStop.convertToGradientStopsArray(stops: stops),
                                  startPoint: startPoint,
                                  endPoint: endPoint,
                                  isFilled: false)
        }
    }
}
