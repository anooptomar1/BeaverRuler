//
//  ComplicationController.swift
//  GRulerAppleWatch Extension
//
//  Created by user on 10/28/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import ClockKit
import WatchKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.forward, .backward])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(NSDate() as Date)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(NSDate() as Date)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        
        
        var template: CLKComplicationTemplate? = nil
        switch complication.family {
        case .modularSmall:
            let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "\(getCurrentData())")
            template = modularTemplate
        case .modularLarge:
            let modularTemplate = CLKComplicationTemplateModularLargeTable()
            modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: "\(getCurrentData())")
            modularTemplate.row1Column1TextProvider = CLKSimpleTextProvider(text: "--")
            modularTemplate.row1Column2TextProvider = CLKSimpleTextProvider(text: "--")
            modularTemplate.row2Column1TextProvider = CLKSimpleTextProvider(text: "--")
            modularTemplate.row2Column2TextProvider = CLKSimpleTextProvider(text: "--")
            template = modularTemplate
        case .utilitarianSmall:
            let modularTemplate = CLKComplicationTemplateUtilitarianSmallRingText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "\(getCurrentData())")
            modularTemplate.fillFraction = 0.7
            modularTemplate.ringStyle = CLKComplicationRingStyle.closed
            template = modularTemplate
        case .utilitarianSmallFlat:
            let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "\(getCurrentData())")
            template = modularTemplate
        case .utilitarianLarge:
            let modularTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "\(getCurrentData())")
            template = modularTemplate
        case .circularSmall:
            let modularTemplate = CLKComplicationTemplateCircularSmallRingText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "\(getCurrentData())")
            modularTemplate.fillFraction = 0.7
            modularTemplate.ringStyle = CLKComplicationRingStyle.closed
            template = modularTemplate
        case .extraLarge:
            let modularTemplate = CLKComplicationTemplateExtraLargeSimpleText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "\(getCurrentData())")
            template = modularTemplate
        }
        
        if (template != nil) {
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template!)
            handler(timelineEntry)
        }
    }
    
    func getCurrentData() -> String {
        // This would be used to retrieve current Chairman Cow health data
        // for display on the watch. For testing, this always returns a
        // constant.
        let myDelegate = WKExtension.shared().delegate as! ExtensionDelegate
        return myDelegate.currentMeasure
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        var template: CLKComplicationTemplate? = nil
        switch complication.family {
        case .modularSmall:
            let modularTemplate = CLKComplicationTemplateModularSmallSimpleText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "--")
            template = modularTemplate
        case .modularLarge:
            let modularTemplate = CLKComplicationTemplateModularLargeTable()
            modularTemplate.row1Column1TextProvider = CLKSimpleTextProvider(text: "--")
            modularTemplate.row1Column2TextProvider = CLKSimpleTextProvider(text: "--")
            modularTemplate.row2Column1TextProvider = CLKSimpleTextProvider(text: "--")
            modularTemplate.row2Column2TextProvider = CLKSimpleTextProvider(text: "--")
            modularTemplate.headerTextProvider = CLKSimpleTextProvider(text: "\(getCurrentData())")
            template = modularTemplate
        case .utilitarianSmall:
            let modularTemplate = CLKComplicationTemplateUtilitarianSmallRingText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "--")
            modularTemplate.fillFraction = 0.7
            modularTemplate.ringStyle = CLKComplicationRingStyle.closed
            template = modularTemplate
        case .utilitarianSmallFlat:
            let modularTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "--")
            template = modularTemplate
        case .utilitarianLarge:
            let modularTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "--")
            template = modularTemplate
        case .circularSmall:
            let modularTemplate = CLKComplicationTemplateCircularSmallRingText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "--")
            modularTemplate.fillFraction = 0.7
            modularTemplate.ringStyle = CLKComplicationRingStyle.closed
            template = modularTemplate
        case .extraLarge:
            let modularTemplate = CLKComplicationTemplateExtraLargeSimpleText()
            modularTemplate.textProvider = CLKSimpleTextProvider(text: "--")
            template = modularTemplate
        }
        handler(template)
    }
    
}
