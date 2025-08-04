import UIKit

/// Contains all help content for the app
struct HelpContent {
    
    // MARK: - All Categories
    
    static let allCategories: [HelpCategory] = [
        quickStartCategory,
        checklistsCategory,
        photosAndNotesCategory,
        contactsCategory,
        filesCategory,
        emergencyCategory,
        importExportCategory,
        profileAndSettingsCategory
    ]
    
    // MARK: - Quick Start Category

    static let quickStartCategory = HelpCategory(
        id: "quickstart",
        title: "Quick Start Guide",
        icon: "star",
        topics: [
            HelpTopic(
                id: "app_overview",
                title: "App Overview",
                content: "The Ship Pilot Checklists app is designed by Pilots, for Pilots. This comprehensive tool helps you manage emergency and routine checklists, maintain critical contacts, and generate professional reports.",
                screenshot: UIImage(named: "help_home_screen"),
                detailedContent: """
                Main Features:
                • Professional Emergency & Standard Checklists created by experienced pilots
                • Custom checklist creation and editing capabilities
                • Emergency SMS with automatic location, tide, and wind data
                • Professional PDF report generation with digital signatures
                • Comprehensive contact management with maritime-specific fields
                • Voice memo recording for documentation
                • Photo attachment to checklist items (up to 4 per item)
                • Complete offline functionality (except tide/wind data)
                
                The app works entirely offline, making it reliable in areas with poor connectivity. Only tide and wind data features require internet access.
                
                📱 Important File Import Tip:
                When receiving .json or .csv files through messaging apps (Signal, iMessage, WhatsApp), you MUST save them to the native Files app first, then share to Ship Pilot Checklists. This extra step is required due to iOS security. See Import & Export help section for details.
                """
            ),
            HelpTopic(
                id: "first_time_setup",
                title: "Setting Up Your Profile",
                content: "Before using emergency features, set up your pilot profile with your name and emergency contacts. This information is used in SMS messages and PDF reports.",
                screenshot: UIImage(named: "help_profile_setup"),
                detailedContent: """
                Essential Setup Steps:
                
                1. Tap the profile icon (person) in the top navigation bar
                2. Enter your name - this appears in SMS messages and PDF headers
                3. Enter your pilot group/organization (optional but recommended)
                4. Add emergency contacts in the Contacts section
                
                Why This Matters:
                • Emergency SMS messages include your name for identification
                • PDF reports show professional headers with your information
                • Coast Guard and emergency responders can quickly identify you
                • Vessel agents receive properly formatted documentation
                
                You can access profile settings anytime from the main menu.
                """
            ),
            HelpTopic(
                id: "navigation_basics",
                title: "Navigation Basics",
                content: "The main menu provides access to all app features. Use the top navigation buttons for search, help, profile, and theme switching.",
                screenshot: UIImage(named: "help_main_navigation"),
                detailedContent: """
                Main Menu Buttons:
                • Included Checklists - Professional emergency and standard checklists
                • Custom Checklists - Create and edit your own checklists
                • Favorites - Quick access to your most-used checklists
                • Contacts - Manage emergency and operational contacts
                • Saved Files - Access PDFs and audio recordings
                
                Top Navigation Icons:
                • Info (i) - App version and privacy information
                • Question mark (?) - This help system
                • Magnifying glass - Search all checklists
                • Person icon - Your pilot profile settings
                • Sun/Moon - Switch between day and night themes
                
                Night Mode:
                The app includes a dedicated night mode designed for bridge operations. The night theme uses a dark background with green text for optimal visibility in low-light conditions.
                """
            ),
            HelpTopic(
                id: "using_checklists_basics",
                title: "Using Checklists - The Basics",
                content: "Open any checklist to start using it. Tap checkboxes to mark items complete. The app automatically adds timestamps and saves your progress.",
                screenshot: UIImage(named: "help_checklist_basics"),
                detailedContent: """
                Basic Checklist Operations:
                • Tap any checkbox to mark an item as completed
                • Timestamps are automatically added when you check items
                • Tap section headers to collapse/expand sections for easier navigation
                • All progress is automatically saved as you work
                
                Enhanced Features:
                • Add photos to document conditions (camera icon next to each item)
                • Add quick notes to specific items (pencil icon)
                • Use the main Notes section for general observations
                • Record voice memos while working through checklists
                
                The bottom toolbar provides access to:
                • Emergency SMS (message icon)
                • GPS location (globe icon)
                • Tide data (wave icon)
                • Wind data (wind icon)
                • Voice recording (microphone icon)
                • PDF generation (document icon)
                • Clear checklist (eraser icon)
                """
            ),
            HelpTopic(
                id: "quick_tips_essentials",
                title: "Essential Tips for New Users",
                content: "Key tips to get the most out of Ship Pilot Checklists from day one. Save time and avoid common issues with these essential practices.",
                screenshot: UIImage(named: "help_quick_tips"),
                detailedContent: """
                🌟 Top 5 Tips for New Users:
                
                1. 📱 File Import Tip:
                When teammates share .json or .csv files via messaging apps:
                • Save the file to your Files app first
                • Then share it to Ship Pilot Checklists
                • Direct imports from messaging apps often fail
                • This works 100% of the time
                
                2. ⭐ Use Favorites:
                • Star your most-used checklists for instant access
                • Critical during emergencies when seconds count
                • Access all favorites from the main menu
                
                3. 📸 Document Everything:
                • Take photos during incidents for evidence
                • Add notes to specific checklist items
                • Generate PDFs before clearing checklists
                
                4. 🚨 Set Up Emergency Contacts First:
                • Add Coast Guard, dispatch, and company contacts
                • Test the Emergency SMS feature during drills
                • Keep VHF channels updated
                
                5. 🌙 Use Night Mode on the Bridge:
                • Tap sun/moon icon to switch themes
                • Green text preserves night vision
                • Reduces screen glare in dark conditions
                
                💡 Pro Tip: Practice using the app during drills so you're familiar with all features before you need them in a real emergency.
                """
            )
        ]
    )
    
    // MARK: - Checklists Category
    
    static let checklistsCategory = HelpCategory(
        id: "checklists",
        title: "Working with Checklists",
        icon: "checklist",
        topics: [
            HelpTopic(
                id: "included_checklists_detailed",
                title: "Professional Built-in Checklists",
                content: "The app includes professionally developed emergency and standard checklists created by experienced maritime pilots for real-world situations.",
                screenshot: UIImage(named: "help_included_checklists_menu"),
                detailedContent: """
                Emergency Checklists Include:
                • Abandon Ship - Complete evacuation procedures
                • Allision - Contact with fixed objects
                • Anchor Dragging - Emergency anchoring situations
                • Blackout - Total power loss procedures
                • Collision - Ship-to-ship contact procedures
                • Distress Call Emergency Assistance - Responding to other vessels
                • Excessive Heel - Stability emergencies
                • Fire - Comprehensive fire response
                • Flooding - Damage control procedures
                • GPS Failure/Spoofing - Navigation equipment failure
                • Grounding - Emergency grounding response
                • Gyro Failure - Compass system failure
                • Loss of Propulsion - Engine failure procedures
                • Loss of Steering - Steering system failure
                • Man Overboard - Person overboard response
                • Medevac via Helicopter - Medical evacuation procedures
                • Medevac to Shore - Shore-based medical transfer
                • Mooring Breakaway from Berth - Emergency departure
                • Tsunami Warning - Natural disaster response
                
                Standard Checklists Include:
                • Change of Conn - Watch relief procedures
                • Master Pilot Exchange (MPX) - Boarding procedures
                • Restricted Visibility - Fog and low visibility operations
                • Pilot Transfer Area - Safe transfer zone assessment
                • Pilot Prep for Embarkation - Personal safety preparation
                • Pilot Ladder Inspection - Safety equipment verification
                • Pilot Prep for Disembarkation - Safe departure preparation
                
                Each checklist is organized by priority:
                • High Priority - Immediate safety-critical actions
                • Medium Priority - Important follow-up actions  
                • Low Priority - Documentation and reporting tasks
                """
            ),
            HelpTopic(
                id: "custom_checklist_creation",
                title: "Creating Custom Checklists",
                content: "Build your own checklists tailored to specific vessels, ports, or operations. Start from scratch or customize existing checklists.",
                screenshot: UIImage(named: "help_custom_checklist_editor"),
                detailedContent: """
                Creating a New Custom Checklist:
                1. Go to Custom Checklists from the main menu
                2. Tap "New Checklist" at the bottom
                3. Enter a descriptive title
                4. Add items by tapping the "+" in each priority section
                5. Drag items between sections or reorder within sections
                6. Tap "Save" when complete
                
                Editing Existing Checklists:
                • Tap the pencil icon next to any custom checklist
                • Add, remove, or reorder items by dragging
                • Edit text by tapping in any text field
                • Press return to quickly add new items below the current one
                • Use the star button to mark as favorite
                
                Converting Included Checklists:
                • Tap the clipboard icon next to any included checklist
                • This creates an editable copy in your Custom Checklists
                • Customize it for specific vessels or operations
                • Original included checklist remains unchanged
                
                Best Practices:
                • Use descriptive titles (e.g., "MV Atlantic Fire Procedures")
                • Organize items by urgency (High/Medium/Low priority)
                • Include vessel-specific equipment references
                • Test your custom checklists during drills
                """
            ),
            HelpTopic(
                id: "favorites_management",
                title: "Managing Favorites",
                content: "Add your most frequently used checklists to Favorites for instant access during critical situations.",
                screenshot: UIImage(named: "help_favorites_screen"),
                detailedContent: """
                Adding to Favorites:
                • For any checklist: Tap the star icon
                • Star becomes filled when added to favorites
                • Works for both included and custom checklists
                
                Using Favorites:
                • Access from main menu "Favorites" button
                • All your starred checklists in one location
                • Faster access during emergencies
                • Can organize favorites into categories
                
                Managing Favorites:
                • Tap star icon again to remove from favorites
                • Swipe left on items in Favorites screen to delete
                • Drag and drop to reorder favorites
                • Create custom categories for organization
                
                Emergency Tip:
                Add your most critical emergency checklists to favorites so you can access them immediately without searching through all available checklists.
                """
            ),
            HelpTopic(
                id: "search_functionality",
                title: "Searching Checklists",
                content: "Quickly find any checklist or specific checklist items using the powerful search feature.",
                screenshot: UIImage(named: "help_search_screen"),
                detailedContent: """
                Using Search:
                1. From main menu, tap the magnifying glass icon
                2. Type what you're looking for
                3. Results show matches in both checklist titles and individual items
                4. Tap any result to open that checklist directly
                
                Search Capabilities:
                • Searches all included and custom checklists
                • Finds matches in checklist titles
                • Searches individual checklist item text
                • Shows which specific item matched your search
                • Real-time results as you type
                
                Search Tips:
                • Use specific terms (e.g., "fire", "anchor", "GPS")
                • Search by equipment names (e.g., "thrusters", "radar")
                • Search by situation (e.g., "blackout", "flooding")
                • Search by action (e.g., "broadcast", "contact")
                
                Perfect for emergency situations when you need to quickly find specific procedures or equipment references.
                """
            ),
            HelpTopic(
                id: "checklist_progress_and_clearing",
                title: "Checklist Progress and Resetting",
                content: "The app automatically saves your checklist progress. You can clear completed checklists to start fresh or generate reports first.",
                screenshot: UIImage(named: "help_checklist_progress"),
                detailedContent: """
                Automatic Progress Saving:
                • All checkmarks are automatically saved
                • Timestamps persist between app sessions
                • Photos and notes are preserved
                • Progress continues even if app is closed
                
                Clearing Checklists:
                1. Open any checklist
                2. Tap the eraser icon in the bottom toolbar
                3. Confirm the clear action
                4. ALL checks, notes, and photos will be removed
                
                Important Notes:
                • Clearing cannot be undone
                • Always generate a PDF report before clearing if you need documentation
                • Built-in checklists reset to their original state
                • Custom checklists keep their structure but lose all user data
                
                Best Practice:
                Generate a PDF report before clearing checklists for your records. This provides documentation of completed procedures for post-incident reports or routine documentation.
                """
            )
        ]
    )
    
    // MARK: - Photos and Notes Category
    
    static let photosAndNotesCategory = HelpCategory(
        id: "photos_notes",
        title: "Photos, Notes & Documentation",
        icon: "text.below.photo",
        topics: [
            HelpTopic(
                id: "adding_photos_detailed",
                title: "Adding Photos to Document Conditions",
                content: "Document visual evidence by adding up to 4 photos to any checklist item. Photos can be taken with the camera or selected from your photo library.",
                screenshot: UIImage(named: "help_photo_picker"),
                detailedContent: """
                Adding Photos:
                1. Tap the camera icon next to any checklist item
                2. Choose "Camera" to take a new photo or "Photo Library" to select existing photos
                3. For photo library: Select multiple photos (up to your remaining limit)
                4. Photos appear as thumbnails below the checklist item
                
                Photo Management:
                • Up to 4 photos per checklist item
                • Tap any photo thumbnail to view full size
                • When viewing photos: tap to dismiss or tap options to remove
                • Photos are automatically included in PDF reports
                
                Photo Quality and Storage:
                • Photos are saved at high quality for documentation
                • Automatic JPEG compression for optimal file sizes
                • Photos stored locally on device for offline access
                • Full-size photos displayed in PDF reports
                
                Best Practices:
                • Take wide shots for context
                • Include close-ups of specific damage or conditions
                • Document equipment positions and settings
                • Capture environmental conditions when relevant
                • Use good lighting when possible for clear documentation
                """
            ),
            HelpTopic(
                id: "item_notes_system",
                title: "Quick Notes for Specific Items",
                content: "Add detailed notes to individual checklist items for specific observations, measurements, or additional context relevant to that particular action.",
                screenshot: UIImage(named: "help_item_notes_editor"),
                detailedContent: """
                Adding Item Notes:
                1. Tap the pencil icon next to any checklist item
                2. Enter your note in the text editor
                3. Tap "Save" to preserve the note
                4. Notes appear below the checklist item in italic text
                
                When to Use Item Notes:
                • Specific equipment readings (e.g., "Engine room reports 15-degree list")
                • Time-sensitive observations (e.g., "Started at 1430 local")
                • Equipment status details (e.g., "Starboard thruster not responding")
                • Communication details (e.g., "Contacted Port Control on Ch. 12")
                • Damage assessments (e.g., "2-meter crack visible in bulkhead")
                
                Note Features:
                • Unlimited text length for detailed observations
                • Automatic saving as you type
                • Notes included in PDF reports under each item
                • Preserved when clearing checklists if you regenerate them
                • Searchable through the main search function
                
                Professional Tip:
                Use item notes for specific details that investigators, port authorities, or vessel management might need. These become part of your official documentation.
                """
            ),
            HelpTopic(
                id: "main_notes_section",
                title: "Main Notes Section",
                content: "The main Notes section at the bottom of each checklist is for general observations, overall situation assessment, and environmental data.",
                screenshot: UIImage(named: "help_main_notes_section"),
                detailedContent: """
                Main Notes Features:
                • Expandable/collapsible section at bottom of every checklist
                • Free-form text entry for general observations
                • Automatic integration of location, tide, and wind data
                • Included as separate section in PDF reports
                
                Typical Uses:
                • Overall situation description
                • Weather and sea conditions
                • Vessel behavior and response
                • Timeline of major events
                • General observations that apply to multiple checklist items
                • Environmental factors affecting operations
                
                Data Integration:
                When you add location, tide, or wind data using the toolbar buttons, this information is automatically appended to the main notes section. This creates a comprehensive environmental picture for documentation.
                
                Keyboard Features:
                • Tap anywhere outside the notes field to dismiss keyboard
                • "Done" button in keyboard toolbar for easy dismissal
                • Notes automatically saved as you type
                • Supports line breaks and formatting
                """
            ),
            HelpTopic(
                id: "location_and_gps",
                title: "GPS Location Data",
                content: "Add precise GPS coordinates to document your exact position during incidents or operations. Essential for emergency response and official reports.",
                screenshot: UIImage(named: "help_gps_location"),
                detailedContent: """
                Adding GPS Location:
                1. Tap the globe icon in the bottom toolbar
                2. Allow location access when prompted
                3. Wait for GPS acquisition (usually 10-30 seconds)
                4. Coordinates automatically added to Notes section
                
                GPS Information Included:
                • Latitude and longitude in decimal degrees (4 decimal places)
                • Accuracy reading (typically ±3-10 meters for marine GPS)
                • Local time when position was recorded
                • Automatic formatting for professional documentation
                
                Location Requirements:
                • Clear view of sky for GPS satellite reception
                • Location permissions enabled in device settings
                • May take longer in poor weather or near large structures
                • 30-second timeout prevents indefinite searching
                
                Emergency Use:
                GPS coordinates are automatically included in emergency SMS messages and are critical for:
                • Coast Guard response coordination
                • Tug boat assistance
                • Medical evacuation planning
                • Post-incident investigation documentation
                
                The app uses high-accuracy GPS suitable for marine navigation and emergency response.
                """
            ),
            HelpTopic(
                id: "tide_wind_environmental_data",
                title: "Tide and Wind Data",
                content: "Automatically fetch and include local tide predictions and wind forecasts in your documentation using NOAA data sources.",
                screenshot: UIImage(named: "help_environmental_data"),
                detailedContent: """
                Adding Tide Data:
                1. First add your GPS location (globe icon)
                2. Tap the wave icon for tide information
                3. App finds nearest NOAA tide station (within 50 nautical miles)
                4. Today's high and low tide predictions automatically added
                
                Adding Wind Data:
                1. First add your GPS location (globe icon)  
                2. Tap the wind icon for forecast information
                3. App fetches NOAA marine weather forecast for your area
                4. Current and next period wind predictions added
                
                Data Sources:
                • NOAA Tides and Currents API for tide predictions
                • National Weather Service marine forecasts for wind
                • Automatic station/forecast office selection based on location
                • Data includes station names and forecast office locations
                
                Information Included:
                • Tide: Times and heights for high/low water in local time
                • Wind: Direction and speed in knots for current and next forecast periods
                • Data formatted for professional maritime documentation
                • Includes source station identification
                
                Requirements:
                • Internet connection required for data retrieval
                • GPS location must be added first
                • Data automatically formatted and added to Notes section
                
                This environmental data is crucial for incident documentation and helps responders understand conditions affecting your vessel.
                """
            ),
            HelpTopic(
                id: "voice_recording_system",
                title: "Voice Recording for Documentation",
                content: "Record audio notes while working through checklists. Perfect for hands-free documentation during dynamic situations.",
                screenshot: UIImage(named: "help_voice_recording"),
                detailedContent: """
                Recording Voice Memos:
                1. Tap the microphone icon in bottom toolbar
                2. Recording starts immediately with visual confirmation
                3. Continue working through checklist while recording
                4. Tap microphone again to stop recording
                5. Enter vessel name when prompted
                6. Recording automatically saved to Saved Files
                
                Recording Features:
                • High-quality audio recording (AAC format)
                • Timer display in navigation bar during recording
                • Visual feedback with red microphone icon
                • Background recording - continue using checklist while recording
                • Automatic file naming with checklist, date, and vessel name
                
                File Naming Convention:
                "ChecklistName_YYYYMMDD_VesselName.m4a"
                Example: "Emergency_Fire_20250224_MV_ATLANTIC.m4a"
                
                When to Use Voice Recording:
                • Complex situations requiring detailed narration
                • When hands are needed for immediate actions
                • To capture real-time observations and decisions
                • For post-incident reconstruction
                • When multiple people are providing input
                • During emergency situations for comprehensive documentation
                
                Audio Quality:
                • 12 kHz sample rate optimized for voice
                • Automatic gain control for consistent levels
                • Low file sizes for easy sharing
                • Compatible with standard audio players
                """
            )
        ]
    )
    
    // MARK: - Contacts Category
    
    static let contactsCategory = HelpCategory(
        id: "contacts",
        title: "Contact Management",
        icon: "person.2",
        topics: [
            HelpTopic(
                id: "contacts_overview_enhanced",
                title: "Maritime Contact Organization",
                content: "Organize all your maritime contacts by categories with specialized fields for marine operations. The Emergency category is protected and always available for SMS messaging.",
                screenshot: UIImage(named: "help_contacts_overview"),
                detailedContent: """
                Default Contact Categories:
                • Emergency (protected - cannot be deleted or renamed)
                • Coast Guard
                • Tug Services  
                • Dispatch
                • Terminal Operations
                • Local Authorities
                • Vessel Agent
                • Pilot Boat Operators
                
                Maritime-Specific Fields:
                • VHF Channel - Radio communication frequencies
                • Call Sign - Vessel or station radio identification
                • Port/Location - Base of operations or jurisdiction
                • Organization - Company or agency affiliation
                • Role/Title - Position or function
                • Notes - Additional operational information
                
                Contact Organization Features:
                • Tap section headers to expand/collapse categories
                • Drag contacts between categories
                • Long-press section headers to reorder categories (except Emergency)
                • Search across all contacts using search bar
                • Automatic tracking of frequently used contacts
                
                Emergency Category Protection:
                The Emergency category is specially protected because it's required for the SMS messaging feature. It cannot be deleted, renamed, or moved from the top position.
                """
            ),
            HelpTopic(
                id: "adding_contacts_methods",
                title: "Adding Individual Contacts",
                content: "Add contacts one at a time either by importing from your phone's contact list or entering information manually with maritime-specific fields.",
                screenshot: UIImage(named: "help_add_single_contact"),
                detailedContent: """
                Adding Single Contacts:
                1. Tap "Add Contact" at bottom of Contacts screen
                2. Choose which category to add the contact to
                3. Either import from phone contacts or enter manually
                
                Import from Phone Contacts:
                • Tap "Import from Contacts" in the contact editor
                • Select contact from your phone
                • Basic information automatically filled in
                • Add maritime-specific fields (VHF, Call Sign, etc.)
                
                Manual Entry:
                Required Fields:
                • Name - Full name or vessel/station identification
                • Phone - Primary contact number
                
                Optional Maritime Fields:
                • Role/Title - Position or function (e.g., "Harbor Master", "Tug Captain")
                • Organization - Company or agency (e.g., "Miller Marine", "USCG Station")
                • VHF Channel - Radio frequencies (e.g., "Ch. 16/12", "156.8 MHz")
                • Call Sign - Radio identification (e.g., "KILO LIMA 7")
                • Port/Location - Area of operations (e.g., "Port of Long Beach")
                • Email - Electronic communication
                • Notes - Additional operational details
                
                Contact Usage Tracking:
                The app automatically tracks when you call or text contacts, prioritizing frequently used contacts in emergency situations.
                """
            ),
            HelpTopic(
                id: "batch_contact_import",
                title: "Batch Contact Import",
                content: "Quickly import multiple contacts from your phone's contact list at once, perfect for initial app setup or team contact sharing.",
                screenshot: UIImage(named: "help_batch_import"),
                detailedContent: """
                Using Batch Import:
                1. Tap "Batch Add Contacts" at bottom of Contacts screen
                2. Select multiple contacts from your phone
                3. All selected contacts imported to timestamped category
                4. Drag contacts to appropriate categories afterward
                
                Import Process:
                • Only contacts with phone numbers are imported
                • Basic information (name, phone, email, organization) automatically transferred
                • Creates new category with import timestamp
                • You can then edit contacts to add maritime-specific fields
                
                After Import Organization:
                • Drag contacts from "Imported" category to appropriate categories
                • Edit individual contacts to add VHF channels, call signs, etc.
                • Delete the "Imported" category when reorganization is complete
                • Consider renaming contacts for clarity (e.g., "John Smith - Harbor Pilot")
                
                Team Setup Strategy:
                1. Import all relevant contacts from your phone
                2. Organize into appropriate maritime categories
                3. Add maritime-specific information (VHF, call signs)
                4. Share completed contact database with team members
                5. Standardize contact information across pilot group
                
                CSV Alternative with Categories:
                Consider using CSV import instead if you need:
                • Automatic category organization during import
                • Bulk addition of maritime-specific fields
                • Import from existing spreadsheets or databases
                • Team-wide standardized contact lists
                
                The CSV import method allows you to specify categories for each contact, eliminating the manual drag-and-drop organization step.
                
                This is the fastest way to get your contact database established when first setting up the app.
                """
            ),
            HelpTopic(
                id: "contact_organization_advanced",
                title: "Advanced Contact Organization",
                content: "Use drag-and-drop to organize contacts and categories. Create custom categories for specific operations or vessel types.",
                screenshot: UIImage(named: "help_contact_organization"),
                detailedContent: """
                Contact Management:
                • Press and hold any contact to drag between categories
                • Changes save automatically when you drop
                • Tap phone icon for direct calling
                • Tap message icon for SMS
                • Long-press contacts for full options menu (edit, delete, call, text)
                
                Category Management:
                • Long-press and drag section headers to reorder categories
                • Emergency category always stays first (protected)
                • Tap settings icon on headers to rename or delete categories
                • Empty categories can be deleted (except Emergency)
                • Create new categories with "Add Category" button
                
                Advanced Organization Tips:
                • Create vessel-specific categories (e.g., "MV Atlantic Contacts")
                • Organize by operation type (e.g., "Tanker Operations", "Container Ops")
                • Use port-specific categories (e.g., "Port of LA Contacts")
                • Group by frequency of use (e.g., "Daily Operations", "Emergency Only")
                
                Search and Usage:
                • Use search bar to quickly find any contact
                • App tracks contact usage frequency
                • Recently contacted appear first in emergency SMS selection
                • Frequently used contacts suggested in operational selections
                
                Category Naming Suggestions:
                • "Port Control" - Harbor masters, traffic control
                • "Vessel Agents" - Ship agents and representatives  
                • "Terminal Ops" - Specific terminal contacts
                • "Marine Services" - Chandlers, repair services
                • "Regulatory" - Port state control, inspectors
                """
            ),
            HelpTopic(
                id: "emergency_contact_usage",
                title: "Emergency Contact Usage",
                content: "During emergencies, the app intelligently prioritizes your Emergency contacts and frequently used operational contacts for quick SMS messaging.",
                screenshot: UIImage(named: "help_emergency_contact_selection"),
                detailedContent: """
                Emergency SMS Contact Selection:
                • Emergency category contacts appear first in selection list
                • Frequently used contacts from all categories shown as suggestions
                • Multi-select capability for sending to multiple recipients
                • Contact usage tracking ensures most important contacts surface first
                
                Daily Contact Operations:
                • Tap phone icon for direct calling from any contact
                • Tap message icon for regular SMS messaging
                • Search contacts using search bar at top
                • Long-press any contact for full options menu
                
                Contact Prioritization:
                The app automatically prioritizes contacts based on:
                • Emergency category membership (highest priority)
                • Recent usage frequency
                • Total historical usage
                • Last contact date
                
                Emergency Category Best Practices:
                • Add your most critical emergency contacts
                • Include: Coast Guard, company dispatch, pilot office emergency
                • Keep this category focused - use other categories for routine contacts
                • Regularly verify Emergency contact information
                • Test Emergency contacts periodically
                
                The Emergency category is always accessible and cannot be accidentally deleted, ensuring your critical contacts are always available when needed most.
                """
            )
        ]
    )
    
    // MARK: - Files Category
    
    static let filesCategory = HelpCategory(
        id: "files",
        title: "Saved Files Management",
        icon: "folder",
        topics: [
            HelpTopic(
                id: "saved_files_overview",
                title: "Finding and Organizing Your Files",
                content: "All your generated PDFs and voice recordings are automatically saved in the Saved Files section with standardized naming for easy identification.",
                screenshot: UIImage(named: "help_saved_files_overview"),
                detailedContent: """
                File Naming Convention:
                "ChecklistName_YYYYMMDD_VesselName.extension"
                
                Examples:
                • "Emergency_Fire_20250224_MV_ATLANTIC.pdf"
                • "Master_Pilot_Exchange_20250224_MSC_LUCIA.pdf"  
                • "Grounding_20250224_VESSEL_NAME.m4a"
                
                File Organization:
                • Files automatically sorted by date (newest first)
                • Alternative sorting by name available
                • Filter by file type (All, PDFs, Audio)
                • Clear file information display with vessel names
                • File size and creation date shown
                
                Automatic File Storage:
                • PDF reports saved when generated from checklists
                • Voice recordings saved when completed
                • All files stored locally on device
                • No cloud storage - complete privacy
                • Files remain available offline
                
                File Information Display:
                Each file shows:
                • Original checklist name
                • Date of creation
                • Vessel name (when provided)
                • File type and size
                • Quick preview capability
                """
            ),
            HelpTopic(
                id: "file_management_operations",
                title: "File Management and Sharing",
                content: "Use sorting and filtering to find specific files quickly. Share files via email, AirDrop, or other apps, or delete files you no longer need.",
                screenshot: UIImage(named: "help_file_management"),
                detailedContent: """
                File Organization Controls:
                • "Sort by Name" - Alphabetical order by checklist name
                • "Sort by Date" - Chronological order (newest first - default)
                • "All Files" - Show both PDFs and audio files
                • "PDFs" - Show only PDF reports
                • "Audio" - Show only voice recordings
                
                File Actions:
                • Tap any file to preview contents
                • Swipe right on file to share immediately
                • Swipe left on file to delete (with confirmation)
                • Use refresh button to update file list
                
                Sharing Options:
                • Email - Attach to email messages
                • AirDrop - Share to nearby devices
                • Messages - Send via text/iMessage
                • Save to Files - Export to iCloud or other cloud services
                • Other Apps - Open in compatible applications
                
                File Preview:
                • PDFs open in full-screen reader
                • Audio files play with standard controls
                • Zoom and scroll support for PDF documents
                • Pause/play/seek controls for audio files
                
                Storage Management:
                • Files stored in app's local document directory
                • No automatic deletion - files persist until manually removed
                • Monitor storage usage through device settings
                • Regular cleanup recommended for older files
                • Consider archiving important files to external storage
                """
            ),
            HelpTopic(
                id: "pdf_reports_detailed",
                title: "Professional PDF Reports",
                content: "Generate comprehensive PDF reports with signatures, photos, and complete documentation suitable for official maritime records.",
                screenshot: UIImage(named: "help_pdf_generation"),
                detailedContent: """
                PDF Report Contents:
                • Professional header with checklist title, pilot name, vessel name, date/time
                • All checklist sections with completion status
                • Timestamps for completed items
                • Quick notes for individual items
                • Full-size photos (up to 4 per item)
                • Main notes section with location, tide, and wind data
                • Digital signature section for pilot and captain
                
                Signature Process:
                1. Choose whether captain signature is required
                2. Enter captain's name if needed
                3. Sign with finger on digital signature pad
                4. Captain signs if required
                5. Both signatures included in final PDF with timestamps
                
                PDF Features:
                • Professional maritime document formatting
                • High-resolution photo inclusion
                • Watermarked with app icon for authenticity
                • Standard PDF format for universal compatibility
                • Optimized file sizes for email sharing
                
                Professional Uses:
                • Post-incident documentation
                • Routine operation records
                • Training documentation
                • Regulatory compliance records
                • Insurance documentation
                • Port state control submissions
                
                The PDF format ensures your documentation is accepted by maritime authorities, insurance companies, and legal proceedings worldwide.
                """
            )
        ]
    )
    
    // MARK: - Emergency Category
    
    static let emergencyCategory = HelpCategory(
        id: "emergency",
        title: "Emergency Features",
        icon: "exclamationmark.triangle",
        topics: [
            HelpTopic(
                id: "emergency_sms_comprehensive",
                title: "Emergency SMS Messaging",
                content: "Send comprehensive emergency messages with your position, vessel information, environmental conditions, and situation description to multiple contacts instantly.",
                screenshot: UIImage(named: "help_emergency_sms_flow"),
                detailedContent: """
                Emergency SMS Process:
                1. Open any checklist and tap the message icon
                2. Select recipients from Emergency and Operational contacts
                3. Enter vessel name when prompted
                4. Add brief situation description
                5. Tap "Send" to transmit to all selected contacts
                
                Automatic SMS Content:
                • Your name (from Profile settings)
                • Vessel name
                • Current checklist being used
                • GPS coordinates (if location data added)
                • Local tide predictions (if tide data added)
                • Wind forecast (if wind data added)
                • Your situation description
                • Timestamp in local time
                
                Contact Selection:
                • Emergency category contacts shown first
                • Operational contacts suggested based on usage frequency
                • Multi-select capability for team notification
                • Recently contacted prioritized for quick selection
                
                Best Practices for Emergency SMS:
                1. Add location data first (globe icon) for precise coordinates
                2. Add tide and wind data for environmental context
                3. Use clear, concise situation descriptions
                4. Select appropriate mix of emergency and operational contacts
                5. Consider follow-up communications for status updates
                
                Example Emergency SMS:
                "Pilot: John Smith
                Vessel: MV ATLANTIC
                Checklist: Emergency_Fire
                Location: 33.7490° N, 118.2437° W (±5m) at 14:30
                Situation: Engine room fire, crew responding
                
                Long Beach Tides:
                14:45 H 5.2′
                20:30 L -1.1′
                
                San Pedro Winds:
                This Afternoon: W 15-20 kts
                Tonight: NW 10-15 kts"
                """
            ),
            HelpTopic(
                id: "emergency_contacts_setup",
                title: "Setting Up Emergency Contacts",
                content: "Properly configure your Emergency contacts category for reliable access during critical situations. This protected category ensures your most important contacts are always available.",
                screenshot: UIImage(named: "help_emergency_contacts_setup"),
                detailedContent: """
                Essential Emergency Contacts:
                • Coast Guard - Local station emergency number
                • Company Dispatch - 24/7 company emergency line
                • Pilot Office Emergency - Pilot association emergency contact
                • Port Control - Harbor emergency coordination
                • Medical Emergency - Marine medical advisory services
                
                Setting Up Emergency Contacts:
                1. Go to Contacts from main menu
                2. Emergency category is at the top (always visible)
                3. Tap "Add Contact" at bottom
                4. Select "Emergency" as the category
                5. Enter contact information with emphasis on:
                   - Accurate phone numbers (verify these work)
                   - VHF backup channels when available
                   - 24/7 availability confirmation
                
                Emergency Category Features:
                • Cannot be deleted (protected for SMS functionality)
                • Cannot be renamed (maintains standardization)
                • Always appears first in contact list
                • Automatically expanded in emergency SMS selection
                • Prioritized in all emergency communications
                
                Verification and Maintenance:
                • Test emergency contact numbers regularly
                • Verify 24/7 availability
                • Update contact information when personnel changes
                • Confirm VHF backup communication methods
                • Practice using emergency SMS feature
                
                Multi-Contact Strategy:
                Include multiple contacts for redundancy:
                • Primary and backup Coast Guard numbers
                • Multiple company contact methods
                • Regional and local authorities
                • Pilot office regular and emergency lines
                """
            ),
            HelpTopic(
                id: "emergency_sms_data_enhancement",
                title: "Enhancing Emergency Messages",
                content: "Add location, environmental, and situational data to provide emergency responders with comprehensive information for effective response coordination.",
                screenshot: UIImage(named: "help_sms_data_enhancement"),
                detailedContent: """
                Data Enhancement Strategy:
                Before sending emergency SMS, add critical information:
                
                1. GPS Location (Globe Icon):
                • Provides exact coordinates for response teams
                • Shows position accuracy for reliability assessment
                • Includes timestamp for position currency
                • Essential for Coast Guard and tug boat response
                
                2. Tide Data (Wave Icon):
                • Current and predicted tide conditions
                • Critical for grounding or shallow water emergencies
                • Helps responders plan approach times
                • Important for anchor operations and vessel refloating
                
                3. Wind Data (Wind Icon):
                • Current and forecast wind conditions
                • Essential for fire emergencies (smoke dispersion)
                • Critical for helicopter operations planning
                • Important for anchor handling and vessel control
                
                4. Situational Context (Notes Section):
                • Brief description of emergency nature
                • Equipment status and availability
                • Personnel situation and injuries
                • Immediate actions taken
                • Assistance requirements
                
                Enhanced Message Benefits:
                • Responders arrive better prepared
                • Reduces back-and-forth communication
                • Speeds up emergency response coordination
                • Provides environmental context for decision-making
                • Creates comprehensive incident documentation
                
                The app will prompt you if no additional data has been added, but you can send basic emergency messages immediately if time is critical.
                """
            )
        ]
    )
    
    // MARK: - Import/Export Category

    static let importExportCategory = HelpCategory(
        id: "import_export",
        title: "Import & Export",
        icon: "square.and.arrow.up.on.square",
        topics: [
            HelpTopic(
                id: "how_to_import_files",
                title: "📱 How to Import Files (IMPORTANT - Read First)",
                content: "Files shared through messaging apps require an extra step. Save files to the Files app first, then share to Ship Pilot Checklists for reliable importing.",
                screenshot: UIImage(named: "help_files_app_import"),
                detailedContent: """
                ⚠️ IMPORTANT: Direct Import from Messaging Apps
                
                When receiving .json or .csv files through messaging apps (Signal, iMessage, WhatsApp, Teams, etc.), iOS security restrictions often prevent direct importing. Follow these steps for reliable imports:
                
                ✅ Recommended Import Method:
                1. In your messaging app, tap and hold the file
                2. Choose "Save to Files"
                3. Select a location (iCloud Drive or On My iPhone)
                4. Open the Files app
                5. Find your saved file
                6. Tap the file to preview it
                7. Tap the Share button (square with arrow)
                8. Select "Ship Pilot Checklists" from the share sheet
                
                Why This Extra Step?
                • Messaging apps store files in protected containers
                • iOS security prevents direct access between apps
                • The Files app provides a neutral, accessible location
                • This method works 100% of the time
                
                Alternative Methods That Also Work:
                • ✅ Email attachments - Usually work directly
                • ✅ AirDrop - Works directly between iOS devices
                • ✅ Cloud storage links - Download to Files first
                • ❌ Direct from messaging apps - Often fails
                
                Supported File Types:
                • .json - For contacts and checklists (universal format)
                • .csv - For contacts and checklists (spreadsheet format)
                • .shipchecklist - For custom checklists only
                
                Troubleshooting:
                If you see "Could not access the file" error:
                • You tried to import directly from a messaging app
                • Save to Files app first, then try again
                • Make sure the file isn't corrupted or empty
                
                💡 Pro Tip:
                Create a folder in Files app called "Ship Pilot Imports" to keep all your import files organized in one place.
                """
            ),
            HelpTopic(
                id: "json_contacts_system",
                title: "Universal Contact Import/Export",
                content: "Use the JSON format for maximum compatibility when sharing contact databases. Works with all email and messaging systems without restrictions.",
                screenshot: UIImage(named: "help_json_contacts_export"),
                detailedContent: """
                ⚠️ IMPORTING JSON FILES: Save to Files app first if receiving through messaging apps (Signal, iMessage, WhatsApp). See "How to Import Files" for detailed instructions.
                
                Exporting Contacts (JSON):
                1. Go to Contacts
                2. Tap "Export Contacts" at bottom
                3. Select categories to include:
                   - All categories pre-selected
                   - Uncheck categories you don't want to export
                   - See contact counts for each category
                4. Tap "Export" to create JSON file
                5. Choose sharing method
                
                Category Preservation:
                • Exported categories maintain their exact names
                • When importing, contacts merge into matching categories
                • New categories created only if they don't exist
                • Emergency category is never duplicated
                • Smart case-insensitive matching (e.g., "emergency" matches "Emergency")
                
                Importing JSON Contacts:
                • Save file to Files app first (if from messaging apps)
                • Share to Ship Pilot Checklists from Files app
                • Contacts automatically organized by category
                • See detailed import summary
                • Option to "View Imported" for quick review
                
                Import Sources That Work:
                ✅ Files app (most reliable)
                ✅ Email attachments (Gmail, Outlook, Apple Mail)
                ✅ AirDrop from other iOS devices
                ✅ Cloud storage (after saving to Files)
                ⚠️ Messaging apps (must save to Files first)
                
                Team Contact Management:
                • Export standardized contact lists for team sharing
                • Backup contact databases for device transitions
                • Share regional contact information between pilot groups
                • Distribute updated contact information efficiently
                • Maintain consistent contact databases across teams
                
                Import Results:
                • Shows contacts added to existing categories
                • Lists any new categories created
                • Preserves all contact fields and information
                • No duplicate Emergency category creation
                """
            ),
            HelpTopic(
                id: "csv_contacts_import",
                title: "Bulk Contact Import from Spreadsheets",
                content: "Import large contact databases from spreadsheets using CSV format with automatic category organization. Ideal for organizations with existing contact management systems.",
                screenshot: UIImage(named: "help_csv_contacts_import"),
                detailedContent: """
                ⚠️ IMPORTING CSV FILES: Save to Files app first if receiving through messaging apps. Direct imports from Signal, WhatsApp, or iMessage often fail due to iOS restrictions.
                
                Creating Contact CSV:
                Required Columns:
                • Name - Contact name or vessel/station identification
                • Phone - Primary contact number
                
                Optional Maritime Columns (flexible naming):
                • Category - Automatically organize contacts into specific categories
                • Email / E-mail / Email Address
                • Organization / Company / Employer
                • Role / Title / Job Title / Position
                • VHF / VHF Channel / Radio Channel
                • Call Sign / Callsign / Radio Call Sign
                • Port / Location / Harbor / Marina
                • Notes / Comments / Additional Info
                
                Category Column Features:
                • Include a "Category" column to auto-organize contacts during import
                • Contacts with matching category names go into existing categories
                • New categories are automatically created for unmatched names
                • If no category specified, contacts go to timestamped "Imported CSV" category
                • Case-insensitive matching (e.g., "emergency" matches "Emergency")
                
                Column Header Recognition:
                The app recognizes many variations of column names:
                • "Phone Number", "Mobile", "Cell", "Telephone" all work for phone
                • "Contact Name", "Full Name", "Person" all work for names
                • "Job Title", "Position", "Rank" all work for roles
                • "Category", "Group", "Type", "Department" all work for categories
                • Partial matches also work (e.g., header containing "phone")
                
                Import Process:
                1. Create spreadsheet with contact information
                2. Include a "Category" column to organize contacts automatically
                3. Save as standard CSV (not UTF-8 CSV)
                4. If receiving via messaging app, save to Files app first
                5. Share CSV file to Ship Pilot Checklists from Files app
                6. Contacts imported into their specified categories
                7. New categories created as needed
                
                Example CSV Structure:
                Name,Phone,Category,VHF Channel,Organization
                John Smith,555-1234,Emergency,16,Coast Guard
                Harbor Master,555-5678,Port Control,12,Port Authority
                Tug Captain,555-9012,Tug Services,8,Miller Marine
                
                Smart Name Generation:
                • If name is empty but organization and role exist, generates name automatically
                • Example: "Miller Marine Dispatcher" from org + role
                • Falls back to "Contact [phone]" if no other info available
                • Helps maintain readable contact lists even with incomplete data
                
                Bulk Import Benefits:
                • Process hundreds of contacts quickly
                • Auto-organize into appropriate categories
                • Import from existing maritime databases
                • Convert from other contact management systems
                • Standardize contact information formats
                • Eliminate manual data entry for large datasets
                
                Post-Import Organization:
                • Review imported contacts for accuracy
                • Categories automatically created and populated
                • Existing categories preserved and updated
                • View summary of imported/updated categories
                • Navigate directly to imported contacts
                • Verify phone number formats and accuracy
                
                Import Results:
                • Shows total contacts imported
                • Lists which categories were updated
                • Lists any new categories created
                • Reports contacts with auto-generated names
                • Indicates any skipped rows (missing phone)
                • Option to "View Imported" for quick review
                """
            ),
            HelpTopic(
                id: "csv_checklist_import",
                title: "Creating Checklists in Excel/Numbers",
                content: "Create checklists using familiar spreadsheet applications and import them as CSV files. Perfect for team standardization and complex checklist development.",
                screenshot: UIImage(named: "help_csv_checklist_creation"),
                detailedContent: """
                ⚠️ IMPORTING REMINDER: If receiving CSV files through messaging apps, save to Files app first before importing.
                
                Spreadsheet Setup:
                1. Create new spreadsheet in Excel, Numbers, or Google Sheets
                2. Column A header: "Priority" (exact spelling required)
                3. Column B header: "Item" (exact spelling required)
                4. No other columns required
                
                Adding Checklist Data:
                Priority Column (A):
                • High Priority - for immediate, safety-critical actions
                • Medium Priority - for important follow-up actions
                • Low Priority - for documentation and reporting
                • Custom priorities - any text creates a new section
                
                Item Column (B):
                • Individual checklist item text
                • Keep items clear and actionable
                • Use active voice (e.g., "Check engine status" not "Engine status checked")
                • Include specific equipment references when needed
                
                Saving and Import:
                1. Save as CSV format (NOT UTF-8 CSV)
                2. If shared via messaging, save to Files app first
                3. From Files app, share to Ship Pilot Checklists
                4. Or from Custom Checklists, tap "Import .csv"
                5. App automatically organizes items by priority sections
                6. Review and edit the imported checklist
                
                Example CSV Structure:
                Priority,Item
                High Priority,Sound general alarm
                High Priority,Determine location of fire
                High Priority,Close watertight doors
                Medium Priority,Contact local authorities
                Low Priority,Document incident details
                
                Team Collaboration Benefits:
                • Multiple team members can contribute to checklist development
                • Version control through spreadsheet applications
                • Easy review and approval process
                • Standardization across vessel types or operations
                """
            ),
            HelpTopic(
                id: "checklist_sharing_system",
                title: "Sharing Custom Checklists",
                content: "Share your custom checklists with colleagues using the universal .shipchecklist format. Perfect for team standardization and procedure distribution.",
                screenshot: UIImage(named: "help_checklist_sharing"),
                detailedContent: """
                ⚠️ RECEIVING SHARED CHECKLISTS: If received through messaging apps, save to Files app first for reliable importing.
                
                Sharing Custom Checklists:
                1. Go to Custom Checklists
                2. Swipe left on any checklist
                3. Tap "Share"
                4. Choose sharing method (Email, AirDrop, Messages, etc.)
                5. File automatically saved with .shipchecklist extension
                
                File Format Benefits:
                • Universal format works across all devices
                • Maintains all checklist structure and content
                • Compatible with email, messaging, and file sharing
                • Direct import when received by other app users
                • Professional file format for maritime industry
                
                Receiving Shared Checklists:
                • Save to Files app if received via messaging
                • Files automatically open in the app when tapped from Files app
                • Import confirmation dialog shows checklist preview
                • Imported checklists appear in Custom Checklists
                • Original sharer's work preserved exactly
                
                Team Standardization:
                • Distribute standardized procedures across pilot groups
                • Share vessel-specific checklists between pilots
                • Collaborate on emergency procedure development
                • Maintain consistency across different vessels
                • Update team procedures centrally and redistribute
                
                Professional Distribution:
                • Share with vessel management for approval
                • Distribute to relief pilots for consistency
                • Provide to training departments for standardization
                • Submit to maritime authorities when required
                • Archive approved procedures for regulatory compliance
                
                The .shipchecklist format ensures your procedures maintain their structure and content when shared across teams and organizations.
                """
            ),
            HelpTopic(
                id: "file_format_compatibility",
                title: "File Format Guide and Best Practices",
                content: "Understanding which file formats work best for different sharing scenarios. Remember: Always save to Files app first when importing from messaging apps.",
                screenshot: UIImage(named: "help_file_formats_guide"),
                detailedContent: """
                🚨 CRITICAL IMPORT TIP:
                Files received through messaging apps (Signal, iMessage, WhatsApp) must be saved to the Files app first before importing. Direct imports from messaging apps often fail due to iOS security restrictions.
                
                Quick Import Guide by Source:
                ✅ Files App → Ship Pilot: ALWAYS WORKS
                ✅ Email → Ship Pilot: Usually works directly
                ✅ AirDrop → Ship Pilot: Works directly
                ⚠️ Messaging Apps → Ship Pilot: Often FAILS
                ✅ Messaging Apps → Files App → Ship Pilot: ALWAYS WORKS
                
                Supported File Formats:
                
                Import Formats:
                • JSON (.json) - Universal format for contacts and checklists
                • CSV (.csv) - Spreadsheet data for contacts and checklists
                • Ship Checklist (.shipchecklist) - Custom checklists only
                
                Export Formats:
                • JSON - Recommended for contacts (universal compatibility)
                • Ship Checklist - Recommended for custom checklists
                • PDF - Generated reports and documentation
                • M4A - Voice recordings
                
                Platform Compatibility Matrix:
                
                JSON Files Work With:
                ✅ All email clients (Gmail, Outlook, Apple Mail, Yahoo)
                ✅ All messaging apps (via Files app method)
                ✅ All cloud services (iCloud, Google Drive, Dropbox, OneDrive)
                ✅ AirDrop and direct file sharing
                ✅ Files app and document management
                ✅ Cross-platform sharing (iOS to Android, etc.)
                
                CSV Files Work With:
                ✅ Most email and messaging systems (via Files app)
                ✅ Excel, Numbers, Google Sheets for editing
                ✅ Database applications for import
                ✅ Most cloud storage services
                
                Ship Checklist Files Work With:
                ✅ Direct app-to-app sharing
                ✅ AirDrop between iOS devices
                ✅ Email and messaging (via Files app method)
                ✅ Files app storage and management
                
                Why JSON is Preferred for Contacts:
                • No corporate email restrictions
                • Works in secure messaging apps (with Files app method)
                • Future-proof standard format
                • Preserves all data relationships
                • Universal platform support
                • No file size limitations
                • Professional appearance in business communications
                
                Best Practices Summary:
                1. ALWAYS use Files app method for messaging app imports
                2. Use JSON for contact sharing (maximum compatibility)
                3. Use .shipchecklist for custom checklists within maritime community
                4. Use PDF for official documentation and reports
                5. Test your import method with a small file first
                6. Keep backup copies in Files app
                7. Create an "Import" folder in Files for organization
                
                Troubleshooting Import Failures:
                • "Could not access file" = Save to Files app first
                • "Invalid format" = Check file isn't corrupted
                • "No data found" = Verify file has content
                • Still having issues? Email the file to yourself
                """
            )
        ]
    )
    
    // MARK: - Profile and Settings Category
    
    static let profileAndSettingsCategory = HelpCategory(
        id: "profile_settings",
        title: "Profile & App Settings",
        icon: "person.crop.circle",
        topics: [
            HelpTopic(
                id: "profile_setup_detailed",
                title: "Setting Up Your Pilot Profile",
                content: "Configure your pilot information for professional SMS messages and PDF report headers. Essential for emergency communications and official documentation.",
                screenshot: UIImage(named: "help_profile_settings"),
                detailedContent: """
                Profile Information Required:
                • Pilot Name - Your full name as it should appear in official documents
                • Pilot Group - Your organization, association, or company name
                
                Profile Usage:
                • Emergency SMS messages include your name for identification
                • PDF report headers show professional formatting
                
                Accessing Profile Settings:
                • Tap person icon in top navigation bar from main menu
                • Available from any screen via navigation
                • Changes automatically saved
                • Required fields validated before emergency use
                
                Privacy and Security:
                • All profile information stored locally on device only
                • No cloud storage or external transmission except in SMS/PDF you generate
                • Complete control over when and how information is shared
                • Information only appears in communications you initiate
                
                The app will prompt you to complete profile setup when attempting to use emergency features if information is missing.
                """
            ),
            HelpTopic(
                id: "night_mode_and_themes",
                title: "Night Mode for Bridge Operations",
                content: "Switch between day and night themes optimized for different lighting conditions. Night mode uses dark backgrounds with green text ideal for bridge operations.",
                screenshot: UIImage(named: "help_night_mode_comparison"),
                detailedContent: """
                Theme Options:
                • Day Mode - Light background with dark blue text and navigation
                • Night Mode - Dark background with green text optimized for low light
                
                Switching Themes:
                • Tap sun/moon icon in top navigation bar
                • Change applies immediately to entire app
                • Setting preserved between app sessions
                • Independent of device system theme
                
                Night Mode Benefits:
                • Reduced eye strain in dark bridge conditions
                • Green text preserves night vision
                • Dark backgrounds minimize light emission
                
                Day Mode Benefits:
                • High contrast for bright daylight conditions
                • Professional appearance for office use
                • Clear visibility in well-lit conditions

                
                The theme setting is independent of your device's system-wide dark mode setting, giving you complete control optimized for maritime operations.
                """
            ),
            HelpTopic(
                id: "app_permissions_and_privacy",
                title: "App Permissions and Privacy",
                content: "The app requires specific permissions for GPS, camera, and microphone features. All data remains on your device with no external transmission except features you control.",
                screenshot: UIImage(named: "help_permissions_screen"),
                detailedContent: """
                Required Permissions:
                
                Location Access:
                • Used only for GPS coordinate display in notes and SMS
                • No tracking or location history stored
                • Only accessed when you tap the globe icon
                • Required for tide and wind data features
                
                Camera Access:
                • Used only for taking photos to attach to checklist items
                • No automatic photo capture
                • Photos stored locally in app documents
                • No photo transmission except in reports you generate
                
                Microphone Access:
                • Used only for voice memo recording
                • No background recording or monitoring
                • Recordings stored locally in app
                • No audio transmission except files you share
                
                Photo Library Access:
                • Used only for selecting existing photos for checklist items
                • No automatic photo access or scanning
                • Only accessed when you choose "Photo Library" option
                
                Contacts Access:
                • Used only when you choose to import contacts
                • No automatic contact scanning or upload
                • Only selected contacts imported to app
                • No contact synchronization or external transmission
                
                Privacy Guarantees:
                • All data stored locally on your device only
                • No cloud storage or external servers
                • No data transmission except SMS and files you explicitly share
                • No analytics, tracking, or usage monitoring
                • No advertising or third-party data sharing
                • Complete offline functionality for all core features
                
                Data Control:
                You have complete control over:
                • When location is accessed (only when you tap globe icon)
                • What photos are taken or selected
                • When voice recordings are made
                • Which contacts are imported
                • What information is included in SMS or PDF reports
                • When and how files are shared
                
                This privacy-first approach ensures your operational data remains under your complete control.
                """
            ),
            HelpTopic(
                id: "app_settings_and_preferences",
                title: "App Settings and Customization",
                content: "Customize the app's behavior and appearance to match your operational preferences and workflow requirements.",
                screenshot: UIImage(named: "help_app_settings"),
                detailedContent: """
                Available Settings:
                
                Theme Selection:
                • Day Mode - Light theme for bright conditions
                • Night Mode - Dark theme with green text for bridge operations
                • Independent of device system settings
                • Instant switching via navigation bar button
                
                Text Size Options (in Help):
                • Small - Compact display for smaller screens
                • Medium - Standard comfortable reading
                • Large - Enhanced visibility for accessibility
                
                Default Behaviors:
                • Automatic progress saving for all checklists
                • Timestamp format includes local time and GMT offset
                • Emergency contacts always prioritized in SMS selection
                • Voice recordings automatically named with checklist and date
                
                File Organization:
                • Standardized naming convention for all generated files
                • Automatic sorting by date (newest first)
                • Filter options for file type (PDF, Audio, All)
                • Local storage only - no cloud synchronization
                
                Contact Management:
                • Automatic usage tracking for emergency prioritization
                • Protected Emergency category cannot be modified
                • Drag-and-drop organization enabled
                • Search functionality across all contact fields
                
                Operational Preferences:
                • All sections start expanded in checklists for quick access
                • Notes section collapsible to maximize checklist space
                • Camera integration with immediate photo preview
                • Multi-photo selection from photo library
                • Automatic keyboard dismissal for efficient workflow
                
                Reset Options:
                • Clear individual checklists (eraser icon in toolbar)
                • No mass data reset to prevent accidental loss
                • Contact data preserved separately from checklist progress
                • Profile information maintained across checklist clears
                
                These settings ensure the app adapts to your specific operational requirements and preferences.
                """
            )
        ]
    )
}
