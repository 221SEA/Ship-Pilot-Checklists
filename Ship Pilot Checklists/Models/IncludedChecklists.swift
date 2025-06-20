//  IncludedChecklists.swift
//  Ship Pilot Checklists

import Foundation

/// A built‑in checklist’s category (emergency vs. standard)
public enum ChecklistCategory: String, Codable {
    case emergency = "Emergency"
    case standard  = "Standard"
}

/// A lightweight, in‑memory representation of a built‑in checklist.
public class ChecklistInfo: Codable {
    public let id: UUID
    public var title: String
    public let category: ChecklistCategory
    public var sections: [ChecklistSection]
    public var isFavorite: Bool

    public init(id: UUID = UUID(),
                title: String,
                category: ChecklistCategory,
                sections: [ChecklistSection],
                isFavorite: Bool = false) {
        self.id = id
        self.title = title
        self.category = category
        self.sections = sections
        self.isFavorite = isFavorite
    }
}


/// A static array of the “included” (built‑in) checklists.
public struct IncludedChecklists {
    public static let all: [ChecklistInfo] = [
        // ───────────────────────────────────────────────
        // Emergency Checklists (alphabetical)

        ChecklistInfo(
            title: "Abandon Ship",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording (when able)", isChecked: false),
                    ChecklistItem(title: "Determine and log own ship’s position", isChecked: false),
                    ChecklistItem(title: "Determine navigational / traffic hazards", isChecked: false),
                    ChecklistItem(title: "Engage manual steering, engines on standby, thrusters on standby", isChecked: false),
                    ChecklistItem(title: "If possible, proceed to calm, protected waters for debarkation", isChecked: false),
                    ChecklistItem(title: "Issue “Mayday” broadcast, monitor VHF Ch. 16, relay emergency information to, and remain in contact with, CG", isChecked: false),
                    ChecklistItem(title: "Make broadcast to inform local traffic of emergency operations", isChecked: false),
                    ChecklistItem(title: "If needed, request assistance from other vessels", isChecked: false),
                    ChecklistItem(title: "Ensure personal flotation gear, appropriate weather clothing, emergency gear [handheld radio, personal EPIRB, etc.] is available for debarkation", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Secure PPU, logbooks, etc. for debarkation", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Contact Office via Emergency SMS (if not yet done)", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Blackout",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording", isChecked: false),
                    ChecklistItem(title: "Identify available navigational resources [gyro (visual bearings), radar (Head-Up mode), PPU, mobile / tablet internal GPS]", isChecked: false),
                    ChecklistItem(title: "Determine and log ship’s position [fix position on PPU]", isChecked: false),
                    ChecklistItem(title: "Identify available maneuvering resources [engines, steering [manual steering, steering gear pumps, standby steering gear room], thrusters, anchors [consider letting go]", isChecked: false),
                    ChecklistItem(title: "Analyze set / drift", isChecked: false),
                    ChecklistItem(title: "Maximize your sea room and direct the ship away from any immediate threats using any available maneuvering resources, slow & stop the ship", isChecked: false),
                    ChecklistItem(title: "Sound danger signal (if applicable)", isChecked: false),
                    ChecklistItem(title: "Consider “Mayday”, “Pan Pan”, or “Securite” broadcast (depending on conditions)", isChecked: false),
                    ChecklistItem(title: "Transmit VHF warning to other vessels of situation", isChecked: false),
                    ChecklistItem(title: "Consider outside maneuvering assistance [tugs, other vessels]", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Determine emergency generator status", isChecked: false),
                    ChecklistItem(title: "Close watertight doors, if applicable", isChecked: false),
                    ChecklistItem(title: "Position engine controls for restoration of propulsion", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Contact CG / local authorities", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Collision",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording (when able)", isChecked: false),
                    ChecklistItem(title: "Sound the danger signal", isChecked: false),
                    ChecklistItem(title: "Manual steering & bridge control of engines", isChecked: false),
                    ChecklistItem(title: "Maneuver ship to minimize danger / damage [by any available means]", isChecked: false),
                    ChecklistItem(title: "Use engine(s) / anchor(s) to slow / stop the ship", isChecked: false),
                    ChecklistItem(title: "Stand by the anchors ... consider letting go", isChecked: false),
                    ChecklistItem(title: "Determine and log ship’s position [fix position on PPU]", isChecked: false),
                    ChecklistItem(title: "Consider “Mayday”, “Pan Pan”, or “Securite” broadcast (depending on conditions)", isChecked: false),
                    ChecklistItem(title: "Determine damage and watertight integrity", isChecked: false),
                    ChecklistItem(title: "Close watertight doors, if applicable", isChecked: false),
                    ChecklistItem(title: "If afloat with damage, consider proceeding to shallow waters and anchoring or safely grounding the ship", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Contact the other vessel; offer assistance, confirm status of personnel / cargo", isChecked: false),
                    ChecklistItem(title: "Transmit VHF warning to other vessels of situation, ask for help if necessary", isChecked: false),
                    ChecklistItem(title: "Contact CG / local authorities", isChecked: false),
                    ChecklistItem(title: "Request Tug assistance", isChecked: false),
                    ChecklistItem(title: "Determine effect of tide, current, present weather, and forecast weather", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Take photos / screenshots of ECDIS, PPU, Own Ship & other vessel, radar", isChecked: false),
                    ChecklistItem(title: "Advise pilot office [potential Pilot relief, engage PR resources]", isChecked: false),
                    ChecklistItem(title: "Drug / Alcohol Test", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Distress Call: Emergency Assistance",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording (when able)", isChecked: false),
                    ChecklistItem(title: "Distress call received", isChecked: false),
                    ChecklistItem(title: "Establish radio contact with distressed vessel", isChecked: false),
                    ChecklistItem(title: "Monitor VHF Ch. 16", isChecked: false),
                    ChecklistItem(title: "Determine and log own ship’s position", isChecked: false),
                    ChecklistItem(title: "Determine and log distressed ship’s position", isChecked: false),
                    ChecklistItem(title: "Determine navigational / traffic hazards", isChecked: false),
                    ChecklistItem(title: "If necessary, proceed to distressed ship’s position", isChecked: false),
                    ChecklistItem(title: "Engage manual steering, engines on standby, thrusters on standby", isChecked: false),
                    ChecklistItem(title: "Relay emergency information to, and remain in contact with, CG", isChecked: false),
                    ChecklistItem(title: "Make broadcast to inform local traffic of emergency assistance operations", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "If necessary, muster mobile fire and medical teams", isChecked: false),
                    ChecklistItem(title: "If necessary, prepare to assist in the fire fighting and/or abandon ship of distressed vessel", isChecked: false),
                    ChecklistItem(title: "If necessary, prepare to take on personnel from distressed vessel", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Update Office via Emergency SMS (if not yet done)", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Excessive Heel",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording (when able)", isChecked: false),
                    ChecklistItem(title: "Switch to manual steering", isChecked: false),
                    ChecklistItem(title: "Call for “ ‘Midships”", isChecked: false),
                    ChecklistItem(title: "Reduce RPMs", isChecked: false),
                    ChecklistItem(title: "Determine navigational / traffic hazards", isChecked: false),
                    ChecklistItem(title: "Once the heading has steadied, order a safe course to be steered", isChecked: false),
                    ChecklistItem(title: "Standby thrusters (if applicable)", isChecked: false),
                    ChecklistItem(title: "Stand by the anchors (if applicable)", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Close watertight doors, if applicable", isChecked: false),
                    ChecklistItem(title: "Determine if stability has been affected (shifting cargo, etc.) before proceeding", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Contact CG / local authorities (if applicable)", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Fire",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording (when able)", isChecked: false),
                    ChecklistItem(title: "Determine and log ship’s position [fix position on PPU]", isChecked: false),
                    ChecklistItem(title: "Determine navigational / traffic hazards", isChecked: false),
                    ChecklistItem(title: "Manual steering / Bridge control of engines", isChecked: false),
                    ChecklistItem(title: "Reduce RPMs and slow the ship", isChecked: false),
                    ChecklistItem(title: "Order a safe course to be steered", isChecked: false),
                    ChecklistItem(title: "Consider turning the ship for smoke / wind effects", isChecked: false),
                    ChecklistItem(title: "Consider proceeding to suitable port, shallow waters, and / or safely grounding the ship", isChecked: false),
                    ChecklistItem(title: "Standby thrusters (if applicable)", isChecked: false),
                    ChecklistItem(title: "Stand by the anchors (if applicable)", isChecked: false),
                    ChecklistItem(title: "Consider “Mayday”, “Pan Pan”, or “Securite” broadcast (depending on conditions), maintain communications with the CG", isChecked: false),
                    ChecklistItem(title: "Determine location of fire, if possible", isChecked: false),
                    ChecklistItem(title: "Close fire screen & watertight doors", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Transmit VHF warning to other vessels of situation, ask for help if necessary", isChecked: false),
                    ChecklistItem(title: "Consider tug assistance", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Contact local authorities (if applicable)", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Flooding",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording (when able)", isChecked: false),
                    ChecklistItem(title: "Determine and log ship’s position [fix position on PPU]", isChecked: false),
                    ChecklistItem(title: "Determine navigational / traffic hazards", isChecked: false),
                    ChecklistItem(title: "Switch to manual steering", isChecked: false),
                    ChecklistItem(title: "Order a safe course to be steered", isChecked: false),
                    ChecklistItem(title: "Reduce RPMs and slow the ship", isChecked: false),
                    ChecklistItem(title: "Consider proceeding to shallow waters and / or safely grounding the ship", isChecked: false),
                    ChecklistItem(title: "Determine damage and watertight integrity", isChecked: false),
                    ChecklistItem(title: "Close watertight doors", isChecked: false),
                    ChecklistItem(title: "Standby thrusters (if applicable)", isChecked: false),
                    ChecklistItem(title: "Stand by the anchors (if applicable)", isChecked: false),
                    ChecklistItem(title: "Consider “Mayday”, “Pan Pan”, or “Securite” broadcast (depending on conditions)", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Transmit VHF warning to other vessels of situation, ask for help if necessary", isChecked: false),
                    ChecklistItem(title: "Consider tug assistance", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Contact CG / local authorities", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "GPS Failure/Spoofing",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording", isChecked: false),
                    ChecklistItem(title: "Identify available maneuvering resources: Propulsion Status: on standby, Steering: engage manual steering, Thrusters: on standby, Anchors: on standby", isChecked: false),
                    ChecklistItem(title: "Identify available navigational resources [gyro (visual bearings), radar (Heads-Up mode with PIs)", isChecked: false),
                    ChecklistItem(title: "Determine and log ship’s position with radar and visual lines of position [LOPs]", isChecked: false),
                    ChecklistItem(title: "Fix position on PPU/ECDIS [engage PPU simulator for dead reckoning?]", isChecked: false),
                    ChecklistItem(title: "Consult tide tables to predict set / drift", isChecked: false),
                    ChecklistItem(title: "Identify the immediate threats [other vessels, navigation hazards, etc.]", isChecked: false),
                    ChecklistItem(title: "Maximize your sea room using any available maneuvering resources to slow or stop the ship and Direct ship away from immediate dangers (grounding, traffic, etc.)", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Investigate other potential GPS sources (Glonass [Russia], Galileo [EU], BeiDou [China], QZSS [Japan], etc.)", isChecked: false),
                    ChecklistItem(title: "Consider emergency broadcast (depending on conditions)", isChecked: false),
                    ChecklistItem(title: "Transmit VHF warning to other vessels of situation", isChecked: false),
                    ChecklistItem(title: "Consider outside maneuvering assistance [tugs, other vessels]", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Contact CG / local authorities", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Grounding",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording (when able)", isChecked: false),
                    ChecklistItem(title: "Sound danger signal (if applicable)", isChecked: false),
                    ChecklistItem(title: "Stop propulsion...do not try to back out", isChecked: false),
                    ChecklistItem(title: "Close watertight doors", isChecked: false),
                    ChecklistItem(title: "Verify status of your maneuvering resources (are they damaged?): Engines, Steering, Engage manual steering, Thrusters, Stand by the anchors ... consider letting go", isChecked: false),
                    ChecklistItem(title: "Consider “Mayday”, “Pan Pan”, or “Securite” broadcast (depending on conditions)", isChecked: false),
                    ChecklistItem(title: "Determine and log ship’s position", isChecked: false),
                    ChecklistItem(title: "Verify traffic situation", isChecked: false),
                    ChecklistItem(title: "If afloat with damage, consider proceeding to shallow water and anchoring or safely re-grounding the ship", isChecked: false),
                    ChecklistItem(title: "Conduct soundings around the ship; determine water depth, bottom type, and direction to deep water", isChecked: false),
                    ChecklistItem(title: "Determine effect of tide, current, present weather, and forecast weather", isChecked: false),
                    ChecklistItem(title: "When is the next high tide?", isChecked: false),
                    ChecklistItem(title: "Sound bilges / tanks; determine flooding situation, if any", isChecked: false),
                    ChecklistItem(title: "Assess hull damage and structural integrity", isChecked: false),
                    ChecklistItem(title: "Request Tug assistance", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Transmit VHF warning to other vessels of situation, ask for help if necessary", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Contact CG / local authorities", isChecked: false),
                    ChecklistItem(title: "Preserve PPU / ECDIS recordings", isChecked: false),
                    ChecklistItem(title: "Position engine controls for restoration of propulsion", isChecked: false),
                    ChecklistItem(title: "Advise pilot office [potential Pilot relief, engage PR resources]", isChecked: false),
                    ChecklistItem(title: "Drug / Alcohol Test", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Gyro Failure",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording (when able)", isChecked: false),
                    ChecklistItem(title: "Engage manual steering", isChecked: false),
                    ChecklistItem(title: "Radars to “Heads Up” mode", isChecked: false),
                    ChecklistItem(title: "Determine magnetic heading ... consider steering by magnetic compass", isChecked: false),
                    ChecklistItem(title: "Record magnetic variation (for future course changes)", isChecked: false),
                    ChecklistItem(title: "Alternatively, use visual / radar navigation aids and landmarks to steer", isChecked: false),
                    ChecklistItem(title: "Determine and log ship’s position", isChecked: false),
                    ChecklistItem(title: "Confirm position on PPU (if possible)", isChecked: false),
                    ChecklistItem(title: "Reduce speed", isChecked: false),
                    ChecklistItem(title: "Change to second gyro, if available", isChecked: false),
                    ChecklistItem(title: "Determine gyro error", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "PPU / Wi-Fi Device: Enable PPU device’s internal GPS (if available)", isChecked: false),
                    ChecklistItem(title: "Use PPU internal heading (if available)", isChecked: false),
                    ChecklistItem(title: "Prepare to use COG", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Contact CG / local authorities (if applicable)", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Loss of Propulsion",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording (when able)", isChecked: false),
                    ChecklistItem(title: "Identify available maneuvering resources: RPMs, Steering [manual steering, steering gear pumps, standby steering gear room], Thrusters, Anchors [consider letting go]", isChecked: false),
                    ChecklistItem(title: "Identify available navigational resources [gyro, radar, PPU]", isChecked: false),
                    ChecklistItem(title: "Determine and log ship’s position [fix position on PPU]", isChecked: false),
                    ChecklistItem(title: "Analyze set / drift", isChecked: false),
                    ChecklistItem(title: "Identify the immediate threats [other vessels, navigation hazards, etc.?]", isChecked: false),
                    ChecklistItem(title: "Maximize your sea room using any available maneuvering resources...direct ship away from immediate dangers (grounding, traffic, etc.)", isChecked: false),
                    ChecklistItem(title: "Sound danger signal (if applicable)", isChecked: false),
                    ChecklistItem(title: "Consider emergency broadcast (depending on conditions)", isChecked: false),
                    ChecklistItem(title: "Transmit VHF warning to other vessels of situation", isChecked: false),
                    ChecklistItem(title: "Consider outside maneuvering assistance [tugs, other vessels]", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Close watertight doors, if applicable", isChecked: false),
                    ChecklistItem(title: "Position engine controls for restoration of propulsion", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Contact CG / local authorities", isChecked: false),
                    ChecklistItem(title: "Drug / Alcohol Test", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Loss of Steering",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording", isChecked: false),
                    ChecklistItem(title: "Identify available maneuvering resources: Status of steering gear pumps, Identify position of the rudder / azipods, Engine & RPMs", isChecked: false),
                    ChecklistItem(title: "Decrease RPMs to slow or stop the ship", isChecked: false),
                    ChecklistItem(title: "Thrusters available and online", isChecked: false),
                    ChecklistItem(title: "Anchors [consider letting go]", isChecked: false),
                    ChecklistItem(title: "Engage alternative steering system / aft steering gear room / emergency override tiller, if available", isChecked: false),
                    ChecklistItem(title: "Synchronize gyros with after steering gear room, if necessary", isChecked: false),
                    ChecklistItem(title: "Identify available navigational resources [gyro, radar, PPU]", isChecked: false),
                    ChecklistItem(title: "Determine and log ship’s position [fix position on PPU]", isChecked: false),
                    ChecklistItem(title: "Analyze set / drift", isChecked: false),
                    ChecklistItem(title: "Identify any immediate threats [other vessels, navigation hazards, etc.]", isChecked: false),
                    ChecklistItem(title: "Maximize your sea room using any available maneuvering resources to slow / stop the ship and Direct ship away from immediate dangers (grounding, traffic, etc.)", isChecked: false),
                    ChecklistItem(title: "Sound danger signal (if applicable)", isChecked: false),
                    ChecklistItem(title: "Consider emergency broadcast (depending on conditions)", isChecked: false),
                    ChecklistItem(title: "Transmit VHF warning to other vessels of situation", isChecked: false),
                    ChecklistItem(title: "Consider outside maneuvering assistance [tugs, other vessels]", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Close watertight doors if applicable", isChecked: false),
                    ChecklistItem(title: "Position steering control (helm, NFU, azipod levers, etc.) for restoration of steering", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Contact CG / local authorities", isChecked: false),
                    ChecklistItem(title: "Drug / Alcohol Test", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Man Overboard",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording (when able)", isChecked: false),
                    ChecklistItem(title: "MOB Report received: verify which side of the vessel", isChecked: false),
                    ChecklistItem(title: "Determine and log ship’s position [deploy MOB marker on PPU / ECDIS]", isChecked: false),
                    ChecklistItem(title: "Release the MOB Lifebuoy", isChecked: false),
                    ChecklistItem(title: "Assign Lookout to maintain constant sight w/ arm pointing in direction", isChecked: false),
                    ChecklistItem(title: "Determine navigational / traffic hazards", isChecked: false),
                    ChecklistItem(title: "Engage manual steering", isChecked: false),
                    ChecklistItem(title: "Swing stern away from MOB side", isChecked: false),
                    ChecklistItem(title: "Initiate Williamson Turn or other appropriate maneuver", isChecked: false),
                    ChecklistItem(title: "Slow the ship", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Add extra lookouts at locations around the ship ... pertinent to the direction the MOB last seen", isChecked: false),
                    ChecklistItem(title: "Prepare thrusters for maneuvering", isChecked: false),
                    ChecklistItem(title: "Notify CG and request assistance from nearby vessels", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Open bridge doors / windows for listening", isChecked: false),
                    ChecklistItem(title: "Determine effect of tide, current, present weather, and forecast weather", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Medevac via Helicopter",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording (when able)", isChecked: false),
                    ChecklistItem(title: "Contact CG / local authorities requesting medevac", isChecked: false),
                    ChecklistItem(title: "Determine and log ship’s position [fix position on PPU]", isChecked: false),
                    ChecklistItem(title: "Evaluate navigational & traffic hazards / weather conditions", isChecked: false),
                    ChecklistItem(title: "Engage manual steering, bridge control of engines, engage thrusters online", isChecked: false),
                    ChecklistItem(title: "Set RPMs for a moderate transfer speed [in consultation with helicopter]", isChecked: false),
                    ChecklistItem(title: "Proceed to a rendezvous area for projected helicopter operations [open water with sea room to enable a steady course during transfer]", isChecked: false),
                    ChecklistItem(title: "Make broadcast to inform local traffic of area of medevac operations", isChecked: false),
                    ChecklistItem(title: "Establish communications with the helicopter", isChecked: false),
                    ChecklistItem(title: "Inform helicopter of planned ship’s position for medevac", isChecked: false),
                    ChecklistItem(title: "Inform helicopter of local weather conditions [wind, visibility, precipitation, cloud height, sea state]", isChecked: false),
                    ChecklistItem(title: "Inform the helicopter of location of helideck", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Consider making ready the rescue boat [in case of MOB]", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "No simultaneous operations ongoing", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Medevac to Shore",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording (when able)", isChecked: false),
                    ChecklistItem(title: "Contact CG / local authorities requesting medevac", isChecked: false),
                    ChecklistItem(title: "Determine and log ship’s position [fix position on PPU]", isChecked: false),
                    ChecklistItem(title: "Evaluate navigational & traffic hazards / weather conditions in transfer area", isChecked: false),
                    ChecklistItem(title: "Set manual steering, bridge control of engines, thrusters online", isChecked: false),
                    ChecklistItem(title: "Proceed to transfer location for medevac [calm waters near appropriate medical care or appropriate airport for air ambulance]", isChecked: false),
                    ChecklistItem(title: "Make broadcast to inform local traffic of area of medevac operations", isChecked: false),
                    ChecklistItem(title: "Ensure air ambulance is on the ground before transferring patient", isChecked: false),
                    ChecklistItem(title: "Remain in transfer area until air ambulance departs", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Consider making ready the rescue boat [in case of MOB]", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "No simultaneous operations ongoing", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Tsunami Warning",
            category: .emergency,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording (when able)", isChecked: false),
                    ChecklistItem(title: "Tsunami alert received from the National Tsunami Warning Center (NTWC)", isChecked: false),
                    ChecklistItem(title: "Determine and log ship’s position", isChecked: false),
                    ChecklistItem(title: "Determine navigational / traffic hazards", isChecked: false),
                    ChecklistItem(title: "Engage manual steering, engines and thrusters on standby", isChecked: false),
                    ChecklistItem(title: "Extend stabilizers (if available)", isChecked: false),
                    ChecklistItem(title: "Secure the anchors", isChecked: false),
                    ChecklistItem(title: "Close watertight doors, weather tight doors, all external openings, and hatches", isChecked: false),
                    ChecklistItem(title: "If at a berth, get the ship underway", isChecked: false),
                    ChecklistItem(title: "Move the ship to open water in greater than 100 meters depth and 0.5 nm from shore (avoid constricted channels)", isChecked: false),
                    ChecklistItem(title: "Position the ship into the face of the anticipated tsunami wave, be prepared for large wave heights and strong currents", isChecked: false),
                    ChecklistItem(title: "Be prepared for more than one tsunami wave [stay on station after the 1st wave passes]", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "If time permits, determine stability and consider reducing free surface effects (empty swimming pools, etc.)", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Contact CG / local authorities (if applicable)", isChecked: false)
                ])
            ]
        ),

        // ───────────────────────────────────────────────
        // Routine Checklists (alphabetical)

        ChecklistInfo(
            title: "Change of Conn",
            category: .standard,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Current ship’s position, route, course, speed, drift angle, and UKC", isChecked: false),
                    ChecklistItem(title: "Deep draft, least depth on route, and air draft", isChecked: false),
                    ChecklistItem(title: "Significant vessel traffic", isChecked: false),
                    ChecklistItem(title: "Navigational hazards", isChecked: false),
                    ChecklistItem(title: "Status of tides, current, and weather conditions", isChecked: false),
                    ChecklistItem(title: "Important ETAs [waypoints, check‑in points, destination]", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Status of propulsion; status of ship’s equipment; thrusters; radars; radios; ECDIS; gyro error", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Tug names, types, bollard pull; VHF working channel; makeup of tugs; recommended vessel speed while using tugs", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Master Pilot Exchange",
            category: .standard,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Pilot information card", isChecked: false),
                    ChecklistItem(title: "Status of propulsion [RPMs, air starts, engine room notices]", isChecked: false),
                    ChecklistItem(title: "Status of ship’s equipment; thrusters; radars; radios; ECDIS; gyro error", isChecked: false),
                    ChecklistItem(title: "Current position, route, course, speed, drift angle, and UKC", isChecked: false),
                    ChecklistItem(title: "Deep draft, least depth on route, and air draft", isChecked: false),
                    ChecklistItem(title: "Navigational hazards; status of tides, current, and weather conditions", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Significant vessel traffic; important ETAs", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Bridge team members on duty", isChecked: false)
                ])
            ]
        ),

        ChecklistInfo(
            title: "Restricted Visibility",
            category: .standard,
            sections: [
                ChecklistSection(title: "High Priority", items: [
                    ChecklistItem(title: "Determine navigational / traffic hazards", isChecked: false),
                    ChecklistItem(title: "Engage manual steering; slow the ship", isChecked: false),
                    ChecklistItem(title: "Sound fog signals; post extra lookout(s)", isChecked: false),
                    ChecklistItem(title: "Check radar settings; acquire and monitor radar targets; monitor VHF Channels 13 & 16", isChecked: false)
                ]),
                ChecklistSection(title: "Medium Priority", items: [
                    ChecklistItem(title: "Open bridge doors / windows for listening", isChecked: false)
                ]),
                ChecklistSection(title: "Low Priority", items: [
                    ChecklistItem(title: "Take notes / start an audio recording", isChecked: false)
                ])
            ]
        )
    ]
}
