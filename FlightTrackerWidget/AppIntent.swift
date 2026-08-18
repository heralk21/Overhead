//
//  AppIntent.swift
//  FlightTrackerWidget
//
//  Created by Heral Kumar on 2026-05-14.
//
//  Intentionally left without AppIntents types. The widget uses a
//  StaticConfiguration and does not require AppIntents. Removing AppIntents
//  avoids generating a `Metadata.appintents` bundle, which otherwise breaks
//  the widget extension when the app is re-signed with a different bundle ID
//  (e.g. sideloading with a personal Apple ID).
