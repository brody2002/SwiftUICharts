//
//  LineChartSubViews.swift
//
//
//  Created by Will Dale on 26/01/2021.
//

import SwiftUI

// MARK: - Single colour
/**
 Sub view gets the line drawn, sets the colour and sets up the animations.
 
 Single colour
 */
internal struct LineChartColourSubView<CD, DS>: View where CD: CTLineChartDataProtocol,
                                                           DS: CTLineChartDataSet,
                                                           DS.DataPoint: CTStandardDataPointProtocol & IgnoreMe {
    private let chartData: CD
    private let dataSet: DS
    private let minValue: Double
    private let range: Double
    private let colour: Color
    private let isFilled: Bool
    
    internal init(
        chartData: CD,
        dataSet: DS,
        minValue: Double,
        range: Double,
        colour: Color,
        isFilled: Bool
    ) {
        self.chartData = chartData
        self.dataSet = dataSet
        self.minValue = minValue
        self.range = range
        self.colour = colour
        self.isFilled = isFilled
    }
    
    @State private var startAnimation: Bool = false
    
    internal var body: some View {
        content
            .background(Color(.gray).opacity(0.000000001))
            .if(chartData.viewData.hasXAxisLabels) { $0.xAxisBorder(chartData: chartData) }
            .if(chartData.viewData.hasYAxisLabels) { $0.yAxisBorder(chartData: chartData) }
            .animateOnAppear(disabled: chartData.disableAnimation, using: chartData.chartStyle.globalAnimation) {
                self.startAnimation = true
            }
            .animateOnDisappear(disabled: chartData.disableAnimation, using: chartData.chartStyle.globalAnimation) {
                self.startAnimation = false
            }
    }
    
    var content: some View {
        if dataSet.isSegmented {
            return AnyView(
                GeometryReader { geometry in
                    ZStack {
                        createSegmentedPath(rect: geometry.frame(in: .local), dataPoints: dataSet.dataPoints, minValue: minValue, range: range)
                    }
                }
            )
            
        } else {
            return AnyView(
                LineShape(dataPoints: dataSet.dataPoints,
                          lineType: dataSet.style.lineType,
                          isFilled: isFilled,
                          minValue: minValue,
                          range: range,
                          ignoreZero: dataSet.style.ignoreZero)
                .ifElse(isFilled, if: {
                    $0
                        .scale(y: animationValue, anchor: .bottom)
                        .fill(Color.white)
                        .overlay {
                            LineShape(dataPoints: dataSet.dataPoints,
                                      lineType: dataSet.style.lineType,
                                      isFilled: isFilled,
                                      minValue: minValue,
                                      range: range,
                                      ignoreZero: dataSet.style.ignoreZero)
                            .scale(y: animationValue, anchor: .bottom)
                            .fill(ImagePaint(image:
                                                Image("chartFillShape").resizable()
                                            ))
                            .foregroundColor(colour)
                        }
                }, else: {
                    $0
                        .trim(to: animationValue)
                        .stroke(colour, style: dataSet.style.strokeStyle.strokeToStrokeStyle())
                })
            )
        }
    }
    
    var animationValue: CGFloat {
        if chartData.disableAnimation {
            return 1
        } else {
            return startAnimation ? 1 : 0
        }
    }
    
    func createSegmentedPath(
        rect: CGRect,
        dataPoints: [any CTStandardDataPointProtocol],
        minValue: Double,
        range: Double
    ) -> some View {
        let pathSegments = segmentedPath(rect: rect, dataPoints: dataPoints, minValue: minValue, range: range)
        return ZStack {
            ForEach(pathSegments, id: \.id) { segment in
                segment.path
                    .stroke(segment.color, lineWidth: 2)
            }
        }
    }
    
    func segmentedPath(
        rect: CGRect,
        dataPoints: [any CTStandardDataPointProtocol],
        minValue: Double,
        range: Double
    ) -> [PathSegment] {
        guard let dataPoints = dataPoints as? [LineChartDataPoint] else {
            return []
        }
        let x: CGFloat = rect.width / CGFloat(dataPoints.count - 1)
        let y: CGFloat = rect.height / CGFloat(range)
        var pathSegments: [PathSegment] = []
        
        var currentPath = Path()
        let firstPoint: CGPoint = CGPoint(x: 0, y: (CGFloat(dataPoints[0].value - minValue) * -y) + rect.height)
        currentPath.move(to: firstPoint)
        
        var previousPoint = firstPoint
        var currentColor = dataPoints.first?.color ?? .appBlue
        var skipColorChange = false
        
        for index in 1 ..< dataPoints.count {
            let nextPoint = CGPoint(x: CGFloat(index) * x, y: (CGFloat(dataPoints[index].value - minValue) * -y) + rect.height)
            let didChangeColor = currentColor != dataPoints[index].color
            
            if currentColor == .appRed && dataPoints[index].color != .appRed && skipColorChange == false {
                skipColorChange = true
            } else {
                skipColorChange = false
            }
            
            if didChangeColor && skipColorChange == false {
                pathSegments.append(PathSegment(path: currentPath, color: currentColor, id: UUID()))
                currentPath = Path()
                currentPath.move(to: previousPoint)
                currentColor = dataPoints[index].color ?? .appBlue
            }
            currentPath.addCurve(
                to: nextPoint,
                control1: CGPoint(x: previousPoint.x + (nextPoint.x - previousPoint.x) / 2, y: previousPoint.y),
                control2: CGPoint(x: nextPoint.x - (nextPoint.x - previousPoint.x) / 2, y: nextPoint.y)
            )
            previousPoint = nextPoint
        }
        pathSegments.append(PathSegment(path: currentPath, color: currentColor, id: UUID()))
        
        return pathSegments
    }
}


// MARK: - Gradient colour
/**
 Sub view gets the line drawn, sets the colour and sets up the animations.
 
 Gradient colour
 */
internal struct LineChartColoursSubView<CD, DS>: View where CD: CTLineChartDataProtocol,
                                                            DS: CTLineChartDataSet,
                                                            DS.DataPoint: CTStandardDataPointProtocol & IgnoreMe {
    private let chartData: CD
    private let dataSet: DS
    private let minValue: Double
    private let range: Double
    private let colours: [Color]
    private let startPoint: UnitPoint
    private let endPoint: UnitPoint
    private let isFilled: Bool
    
    internal init(
        chartData: CD,
        dataSet: DS,
        minValue: Double,
        range: Double,
        colours: [Color],
        startPoint: UnitPoint,
        endPoint: UnitPoint,
        isFilled: Bool
    ) {
        self.chartData = chartData
        self.dataSet = dataSet
        self.minValue = minValue
        self.range = range
        self.colours = colours
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.isFilled = isFilled
    }
    
    @State private var startAnimation: Bool = false
    
    internal var body: some View {
        LineShape(dataPoints: dataSet.dataPoints,
                  lineType: dataSet.style.lineType,
                  isFilled: isFilled,
                  minValue: minValue,
                  range: range,
                  ignoreZero: dataSet.style.ignoreZero)
        .ifElse(isFilled, if: {
            $0
                .scale(y: animationValue, anchor: .bottom)
                .fill(LinearGradient(gradient: Gradient(colors: colours),
                                     startPoint: startPoint,
                                     endPoint: endPoint))
        }, else: {
            $0
                .trim(to: animationValue)
                .stroke(LinearGradient(gradient: Gradient(colors: colours),
                                       startPoint: startPoint,
                                       endPoint: endPoint),
                        style: dataSet.style.strokeStyle.strokeToStrokeStyle())
        })
        .background(Color(.gray).opacity(0.000000001))
        .if(chartData.viewData.hasXAxisLabels) { $0.xAxisBorder(chartData: chartData) }
        .if(chartData.viewData.hasYAxisLabels) { $0.yAxisBorder(chartData: chartData) }
        .animateOnAppear(disabled: chartData.disableAnimation, using: chartData.chartStyle.globalAnimation) {
            self.startAnimation = true
        }
        .animateOnDisappear(disabled: chartData.disableAnimation, using: chartData.chartStyle.globalAnimation) {
            self.startAnimation = false
        }
    }
    
    var animationValue: CGFloat {
        if chartData.disableAnimation {
            return 1
        } else {
            return startAnimation ? 1 : 0
        }
    }
}

// MARK: - Gradient with stops
/**
 Sub view gets the line drawn, sets the colour and sets up the animations.
 
 Gradient with stops
 */
internal struct LineChartStopsSubView<CD, DS>: View where CD: CTLineChartDataProtocol,
                                                          DS: CTLineChartDataSet,
                                                          DS.DataPoint: CTStandardDataPointProtocol & IgnoreMe {
    private let chartData: CD
    private let dataSet: DS
    private let minValue: Double
    private let range: Double
    private let stops: [Gradient.Stop]
    private let startPoint: UnitPoint
    private let endPoint: UnitPoint
    private let isFilled: Bool
    
    internal init(
        chartData: CD,
        dataSet: DS,
        minValue: Double,
        range: Double,
        stops: [Gradient.Stop],
        startPoint: UnitPoint,
        endPoint: UnitPoint,
        isFilled: Bool
    ) {
        self.chartData = chartData
        self.dataSet = dataSet
        self.minValue = minValue
        self.range = range
        self.stops = stops
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.isFilled = isFilled
    }
    
    @State private var startAnimation: Bool = false
    
    internal var body: some View {
        LineShape(dataPoints: dataSet.dataPoints,
                  lineType: dataSet.style.lineType,
                  isFilled: isFilled,
                  minValue: minValue,
                  range: range,
                  ignoreZero: dataSet.style.ignoreZero)
        .ifElse(isFilled, if: {
            $0
                .scale(y: animationValue, anchor: .bottom)
                .fill(LinearGradient(gradient: Gradient(stops: stops),
                                     startPoint: startPoint,
                                     endPoint: endPoint))
        }, else: {
            $0
                .trim(to: animationValue)
                .stroke(LinearGradient(gradient: Gradient(stops: stops),
                                       startPoint: startPoint,
                                       endPoint: endPoint),
                        style: dataSet.style.strokeStyle.strokeToStrokeStyle())
        })
        .background(Color(.gray).opacity(0.000000001))
        .if(chartData.viewData.hasXAxisLabels) { $0.xAxisBorder(chartData: chartData) }
        .if(chartData.viewData.hasYAxisLabels) { $0.yAxisBorder(chartData: chartData) }
        .animateOnAppear(disabled: chartData.disableAnimation, using: chartData.chartStyle.globalAnimation) {
            self.startAnimation = true
        }
        .animateOnDisappear(disabled: chartData.disableAnimation, using: chartData.chartStyle.globalAnimation) {
            self.startAnimation = false
        }
    }
    
    var animationValue: CGFloat {
        if chartData.disableAnimation {
            return 1
        } else {
            return startAnimation ? 1 : 0
        }
    }
}
