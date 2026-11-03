//
//  ImageAsset.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

import Foundation

enum ImageAsset: String, CaseIterable {
    
    case fridge = "temp_trash_fridge"
    case washer = "temp_trash_washer"
    case monitor = "temp_trash_monitor"
    case tire = "temp_trash_tire"
    case jugYellow = "temp_trash_jug_yellow"
    case waterJugBlue = "temp_trash_water_jug_blue"
    case waterBottleBlue = "temp_trash_water_bottle_blue"
    case bottleBrown = "temp_trash_bottle_brown"
    case bottleOrange = "temp_trash_bottle_orange"
    case bottleGreen = "temp_trash_bottle_green"
    case canOrange = "temp_trash_can_orange"
    case canGreen = "temp_trash_can_green"
    case containerPink = "temp_trash_container_pink"
    case tube = "temp_trash_tube"
    case spoon = "temp_trash_spoon"
    case fork = "temp_trash_fork"
    case net = "temp_trash_net"
    
    static let large: [ImageAsset] = [.fridge, .washer, .monitor, .tire]
    static let small = allCases.filter { !large.contains($0) && $0 != .net }
}
