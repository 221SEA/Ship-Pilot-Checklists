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
        importExportCategory
    ]
    
    // MARK: - Quick Start Category
    
    static let quickStartCategory = HelpCategory(
        id: "quickstart",
        title: "Quick Start Guide",
        icon: "star",
        topics: [
            HelpTopic(
                id: "basics",
                title: "App Basics",
                content: "The Ship Pilot Checklists app is designed by Pilots, for Pilots. We have included some of what we think are the most useful checklists, but we've also designed the app so you can customize those checklists, or create / import your own. The app is rich in features to help you during emergency or routine situations.",
                screenshot: UIImage(named: "help_home_screen"),
                detailedContent: """
                • Tap 'Included Checklists' to access built-in Pilot created checklists
                • Tap 'Custom Checklists' to customize included, or create or import your own checklists
                • Tap 'Favorites' to quickly access your most-used checklists
                • Tap 'Contacts' to manage your emergency and operational contacts
                • Tap 'Saved Files' to access your PDFs and audio recordings
                
                The app works entirely offline, except for tide and wind data which requires internet access.
                """
            ),
            HelpTopic(
                id: "opening_checklist",
                title: "Opening a Checklist",
                content: "Select a checklist from Included Checklists, Custom Checklists, or Favorites. You can also search for a specific checklist using the search icon in the main menu.",
                screenshot: UIImage(named: "help_checklist_selection"),
                detailedContent: """
                • Tap on the checklist name to open it
                • The star icon is to add to Favorites
                • The clipboard icon is to add to Custom Checklists
                """
            ),
            HelpTopic(
                id: "completing_items",
                title: "Completing Checklist Items",
                content: "Tap any checkbox to mark an item complete. The app automatically adds a timestamp when you check an item.",
                screenshot: UIImage(named: "help_checking_items"),
                detailedContent: """
                • Tap any checkbox to mark an item as completed
                • Tap again to uncheck an item
                • When you check an item, the current time (local and GMT time zone) is recorded as a timestamp
                • Tap a section header to collapse or expand that section
                """
            ),
            HelpTopic(
                id: "creating_pdf",
                title: "Creating a PDF Report",
                content: "Tap the document icon in the lower right of the bottom navigation toolbar to generate a PDF of your current checklist. Enter the vessel name when prompted, then add optional signatures.",
                screenshot: UIImage(named: "help_pdf_generation"),
                detailedContent: """
                The PDF will include:
                • Checklist title, pilot name, vessel name, and date
                • All checklist items (checked and unchecked)
                • Any notes or photos you've added
                • Your signature and optionally the captain's signature
                
                The generated PDF is automatically saved to the Saved Files section of the app. You can also share it immediately via email, AirDrop, etc.
                """
            )
        ]
    )
    
    // MARK: - Checklists Category
    
    static let checklistsCategory = HelpCategory(
        id: "checklists",
        title: "Using Checklists",
        icon: "checklist",
        topics: [
            HelpTopic(
                id: "included_checklists",
                title: "Built-in Checklists",
                content: "The app includes professionally created emergency and standard checklists designed for ship pilots.",
                screenshot: UIImage(named: "help_included_checklists"),
                detailedContent: """
                Built-in checklists are organized into two categories:
                
                1. Emergency Checklists: For critical situations like fire, collision, or blackout
                2. Standard Checklists: For routine operations like restricted visibility or MPX
                
                Use checklists:
                • Mark items as complete
                • Add quick notes to items
                • Add up to 4 photos, from the gallery or your camera, to individual items
                • Star any checklist to add it to your Favorites
                • Tap the clipboard icon to create a custom version that you can edit as you like
                """
            ),
            HelpTopic(
                id: "custom_checklists",
                title: "Custom Checklists",
                content: "Create your own checklists or customize existing ones for specific vessels or operations.",
                screenshot: UIImage(named: "help_custom_checklists"),
                detailedContent: """
                To create a completely new custom checklist:
                1. Go to Custom Checklists
                2. Tap "New Checklist" at the bottom
                3. Enter a title and add items to each priority section
                4. Tap "Save" when finished
                
                You can:
                • Add, edit, or delete items
                • Drag items to reorder or move between sections
                • Mark a checklist as a favorite
                • Share your custom checklist with other app users
                """
            ),
            HelpTopic(
                id: "favorites",
                title: "Using Favorites",
                content: "Add your most-used checklists to Favorites for quick access.",
                screenshot: UIImage(named: "help_favorites"),
                detailedContent: """
                To add a checklist to favorites:
                • For built-in checklists: Tap the star icon next to any checklist
                • For custom checklists: Tap the star icon next to any checklist
                
                To access your favorites:
                • Tap "Favorites" on the main menu
                • Your favorites are shown in one convenient location
                
                To remove from favorites:
                • Tap the star icon again to unfavorite
                • Or swipe left on the item in the Favorites screen and tap Delete
                """
            ),
            HelpTopic(
                id: "searching",
                title: "Searching Checklists",
                content: "Quickly find any checklist using the search function.",
                screenshot: UIImage(named: "help_search"),
                detailedContent: """
                To search all checklists:
                1. From the main menu, tap the magnifying glass icon in the top navigation bar
                2. Type what you're looking for
                3. Results will show matches from both built-in and custom lists
                
                The search looks for matches in:
                • Checklist titles
                • Individual checklist items
                • Notes you've added
                """
            )
        ]
    )
    
    // MARK: - Photos and Notes Category
    
    static let photosAndNotesCategory = HelpCategory(
        id: "photos_notes",
        title: "Photos & Notes",
        icon: "text.below.photo",
        topics: [
            HelpTopic(
                id: "adding_photos",
                title: "Adding Photos to Items",
                content: "Document conditions by adding up to 4 photos to any checklist item. Tap the image icon next to any item to add photos.",
                screenshot: UIImage(named: "help_adding_photos"),
                detailedContent: """
                To add photos to a checklist item:
                1. Tap the camera icon next to any checklist item
                2. Choose "Camera" to take a new photo or "Photo Library" to select existing photos
                3. Photos will appear as thumbnails below the item
                
                To view or manage photos:
                • Tap any photo thumbnail to view it full size
                • When viewing, you can also remove the photo from the item
                
                Photos are saved with the checklist and will appear (larger versions) in the PDF when exported.
                """
            ),
            HelpTopic(
                id: "item_notes",
                title: "Adding Quick Notes to Items",
                content: "Add detailed quick notes to any checklist item by tapping the note icon. These quick notes will be included in the PDF report.",
                screenshot: UIImage(named: "help_item_notes"),
                detailedContent: """
                To add a note to a specific checklist item:
                1. Tap the note icon (pencil) next to any checklist item
                2. Type your note in the editor
                3. Tap "Save" when done
                
                Your notes will:
                • Appear below the checklist item
                • Be saved with the checklist
                • Be included in the PDF report
                
                This is useful for adding specific details relevant to that checklist item.
                """
            ),
            HelpTopic(
                id: "main_notes",
                title: "Using the Notes Section",
                content: "The main Notes section at the bottom of each checklist is for general notes that apply to the entire checklist.",
                screenshot: UIImage(named: "help_main_notes"),
                detailedContent: """
                The Notes section at the bottom of each checklist can be used for:
                • General observations
                • Additional information
                • Context that applies to multiple items
                • This is also where location, tide and wind data is presented
                
                You can collapse/expand the Notes section by tapping the "Notes" header.
                
                These notes will be included in a separate section of the PDF report.
                """
            ),
            HelpTopic(
                id: "location_data",
                title: "Adding Location Data",
                content: "Tap the globe icon in the toolbar to add your current GPS coordinates to the Notes section.",
                screenshot: UIImage(named: "help_location_data"),
                detailedContent: """
                To add your current location to notes:
                1. Tap the globe icon in the lower toolbar
                2. Wait for GPS to acquire your position
                3. Your coordinates will be added to the Notes section
                
                This feature:
                • Requires location permissions
                • Requires your device has GPS capability and a clear view of the sky
                • Includes accuracy information
                • Includes a timestamp
                
                The location is added to the Notes section and will be included in any emergency SMS or PDF export.
                """
            ),
            HelpTopic(
                id: "tide_wind_data",
                title: "Adding Tide & Wind Data",
                content: "Tap the wave or wind icons to automatically fetch and add local tide and wind data to your notes.",
                screenshot: UIImage(named: "help_tide_wind"),
                detailedContent: """
                To add environmental data:
                1. Add your location first (tap the globe icon)
                2. Tap the wave / arrow icon to add tide information (closest tide station within 50nm)
                3. Tap the wind icon to add wind forecast
                
                This feature:
                • Requires internet connection
                • Uses NOAA data sources
                • Adds predicted tide times and heights
                • Adds predicted wind direction and speed in knots
                
                This data is added to the Notes section and included in any emergency SMS or PDF export.
                """
            ),
            HelpTopic(
                id: "voice_recording",
                title: "Recording Voice Memos",
                content: "Tap the microphone icon to record audio notes. These are useful when you need to document something quickly without typing.",
                screenshot: UIImage(named: "help_voice_recording"),
                detailedContent: """
                To record a voice memo:
                1. Tap the microphone icon in the lower toolbar
                2. Recording begins immediately
                3. Tap the microphone icon again to stop recording
                4. Enter the vessel name when prompted
                
                Voice recordings are:
                • Saved automatically to the Saved Files section
                • Named with the checklist name, date, and vessel name
                • Accessible for playback or sharing later
                
                This is especially useful when you need to document details hands-free.
                """
            )
        ]
    )
    
    // MARK: - Contacts Category - ENHANCED
    
    static let contactsCategory = HelpCategory(
        id: "contacts",
        title: "Managing Contacts",
        icon: "person.2",
        topics: [
            HelpTopic(
                id: "contacts_overview",
                title: "Contacts Overview",
                content: "The Contacts section helps you organize and quickly access emergency contacts, port authorities, and other maritime contacts from directly within the app.",
                screenshot: UIImage(named: "help_contacts_overview"),
                detailedContent: """
                The Contacts section organizes maritime contacts by categories:
                • Emergency
                • Coast Guard
                • Tug Services
                • Dispatch
                • Terminal Operations
                • Local Authorities
                • Vessel Agent
                • Pilot Boat Operators
                
                You can create additional categories as needed. Tap section headers to expand/collapse categories for better organization.
                """
            ),
            HelpTopic(
                id: "adding_contacts",
                title: "Adding Individual Contacts",
                content: "Add contacts individually by selecting from your phone contacts or enter information manually.",
                screenshot: UIImage(named: "help_add_contact"),
                detailedContent: """
                To add a single contact:
                1. Go to Contacts
                2. Tap "Add Single Contact" at the bottom
                3. Choose which category to add to
                4. Either:
                   • Tap "Import from Contacts" to select from your phone
                   • Manually enter the information
                
                Required fields:
                • Name
                • Phone Number
                
                Optional maritime fields:
                • VHF Channel
                • Call Sign
                • Port/Location
                • Organization
                • Role/Title
                • Email
                • Notes
                """
            ),
            HelpTopic(
                id: "batch_import",
                title: "Batch Importing Contacts",
                content: "Quickly import multiple contacts from your phone's contact list.",
                screenshot: UIImage(named: "help_batch_import"),
                detailedContent: """
                To import multiple contacts at once:
                1. Go to Contacts
                2. Tap "Batch Import" at the bottom
                3. Select multiple contacts from your phone
                
                These contacts will be:
                • Added to an "Imported" category with timestamp
                • Available to drag and drop into other categories
                • Automatically filled with available information (name, phone, email, organization)
                
                This is useful when setting up the app with your existing contacts.
                """
            ),
            HelpTopic(
                id: "batch_export_new",
                title: "Batch Export Contacts",
                content: "Export multiple contact categories at once for backup or sharing.",
                screenshot: UIImage(named: "help_batch_export"),
                detailedContent: """
                To export multiple contact categories:
                1. Go to Contacts
                2. Tap "Batch Export" at the bottom
                3. Select which categories to export:
                   • Check/uncheck individual categories
                   • See contact counts for each category
                   • All categories are pre-selected
                4. Tap "Export" to create a .shipcontacts file
                
                The exported file:
                • Contains all selected categories and contacts
                • Can be shared via email, AirDrop, messaging, etc.
                • Can be imported by other users with the app
                • Perfect for standardizing contact databases across teams
                
                This is ideal for:
                • Backing up your contact database
                • Sharing contact lists with colleagues
                • Distributing standard contact lists to pilot teams
                """
            ),
            HelpTopic(
                id: "organizing_contacts",
                title: "Organizing Contacts",
                content: "Drag and drop contacts between categories to keep them organized.",
                screenshot: UIImage(named: "help_organize_contacts"),
                detailedContent: """
                To organize your contacts:
                1. Press and hold on any contact
                2. Drag it to another category
                3. Release to drop it there
                
                To manage categories:
                • Tap "Add Category" to create new categories
                • Expand/collapse categories by tapping the header
                • System categories (Emergency, Coast Guard, etc.) cannot be deleted
                • User-created categories can be deleted when empty
                
                Keep your most important contacts in the Emergency category for quick access during emergencies.
                """
            ),
            HelpTopic(
                id: "using_contacts",
                title: "Using Contacts",
                content: "Quickly call or text contacts, or select them for emergency SMS messages.",
                screenshot: UIImage(named: "help_using_contacts"),
                detailedContent: """
                From the Contacts list:
                • Tap the phone icon to call a contact directly
                • Tap the message icon to text a contact
                • Tap and hold any contact to see all options (call, text, edit, delete)
                • Search contacts using the search bar at the top
                
                During an emergency:
                • When using Emergency SMS, you'll be able to select from both emergency and operational contacts
                • Frequently used contacts will appear at the top of the selection list
                • The app tracks usage to surface your most important contacts
                """
            )
        ]
    )
    
    // MARK: - Files Category
    
    static let filesCategory = HelpCategory(
        id: "files",
        title: "Saved Files",
        icon: "folder",
        topics: [
            HelpTopic(
                id: "saved_files_overview",
                title: "Finding Your Saved Files",
                content: "All your PDFs and audio recordings are automatically saved in the Saved Files section. Access them from the main menu by tapping 'Saved Files'.",
                screenshot: UIImage(named: "help_saved_files"),
                detailedContent: """
                The Saved Files section shows:
                • PDF reports generated from checklists
                • Voice recordings you've created from within a checklist
                
                Files are named with:
                • Checklist name
                • Date (YYYYMMDD format)
                • Vessel name
                
                Example: "Emergency_Fire_20250724_MV_ATLANTIC.pdf"
                """
            ),
            HelpTopic(
                id: "file_management",
                title: "Managing Files",
                content: "Use the sort and filter options to find specific files. Swipe to share or delete files.",
                screenshot: UIImage(named: "help_file_management"),
                detailedContent: """
                To find specific files:
                • Tap "Sort by Name" or "Sort by Date" to change the order
                • Tap "All Files", "PDFs", or "Audio" to filter by file type
                
                To manage files:
                • Swipe right on a file to share it
                • Swipe left on a file to delete it
                
                Tap any file to preview its contents.
                """
            ),
            HelpTopic(
                id: "sharing_files",
                title: "Sharing Files",
                content: "Share your PDF reports and audio recordings via email, AirDrop, messaging, or other apps.",
                screenshot: UIImage(named: "help_sharing_files"),
                detailedContent: """
                To share a file:
                1. Swipe right on any file
                2. Tap "Share"
                3. Select your preferred sharing method:
                   • Email
                   • AirDrop
                   • Messages
                   • Save to Files
                   • Other apps
                
                This allows you to send reports to your office, vessel agents, or other pilots.
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
                id: "emergency_sms",
                title: "Sending Emergency SMS",
                content: "Quickly send your position, vessel information, and conditions to emergency contacts with a few taps.",
                screenshot: UIImage(named: "help_emergency_sms"),
                detailedContent: """
                To send an emergency SMS:
                1. Open any checklist
                2. Tap the message icon (📱) in the toolbar
                3. Select one or more emergency contacts (both Emergency and Operational contacts available)
                4. Enter the vessel name when prompted
                5. Add a brief situation description
                6. Tap "Send"
                
                The SMS includes:
                • Your name (from Profile)
                • Vessel name
                • Current checklist name
                • GPS location (if added)
                • Tide and wind data (if added)
                • Your situation description
                
                For best results, add location, tide, and wind data before sending.
                """
            ),
            HelpTopic(
                id: "emergency_contacts",
                title: "Setting Up Emergency Contacts",
                content: "Add important contacts to the Emergency category for quick access during emergencies.",
                screenshot: UIImage(named: "help_emergency_contacts"),
                detailedContent: """
                To set up emergency contacts:
                1. Go to Contacts
                2. Open the Emergency category
                3. Tap "Add Single Contact" at the bottom
                4. Select "Emergency" as the category
                5. Enter or import contact information
                
                Emergency contacts will be:
                • Available for selection when sending emergency SMS
                • Shown at the top of the contact selection screen
                • Prioritized in the contact suggestion system
                
                Make sure to add these contacts before you need them in an emergency.
                """
            )
        ]
    )
    
    // MARK: - Import/Export Category - ENHANCED
    
    static let importExportCategory = HelpCategory(
        id: "import_export",
        title: "Importing & Exporting",
        icon: "square.and.arrow.up.on.square",
        topics: [
            HelpTopic(
                id: "import_csv_checklist",
                title: "Importing Checklists from CSV",
                content: "Create checklists in Excel or Numbers and import them as CSV files.",
                screenshot: UIImage(named: "help_import_csv"),
                detailedContent: """
                To import a checklist from CSV:
                
                1. Create a spreadsheet file with these column headers. Text must be exactly "Priority" and "Item" for the app to detect:
                   • Column A: Priority
                   • Column B: Item
                
                2. Add rows for individual items with this format:
                   • Priority value: This is where you can use any category you want (Initial Actions, Communications, Damage Control, Post Incident, etc.)
                   • Item value: The checklist item text (Sound General Alarm, etc.)
                
                3. Save as .csv format from Excel or Numbers (NOT UTF-8 CSV)
                
                4. In the app:
                   • Go to Custom Checklists
                   • Tap "Import .csv"
                   • Select your CSV file
                
                The app will automatically detect the CSV format and organize items by priority sections.
                """
            ),
            HelpTopic(
                id: "sharing_checklists",
                title: "Sharing Custom Checklists",
                content: "Share your custom checklists with other pilots.",
                screenshot: UIImage(named: "help_share_checklist"),
                detailedContent: """
                To share a custom checklist:
                1. Go to Custom Checklists
                2. Swipe left on any checklist
                3. Tap "Share"
                4. Choose how to share (Email, AirDrop, etc.)
                
                The shared file:
                • Has a .shipchecklist extension
                • Contains all sections and items
                • Can be opened directly on another device with the app
                
                This is great for sharing specialized checklists with colleagues.
                """
            ),
            HelpTopic(
                id: "exporting_contacts_enhanced",
                title: "Exporting Contact Lists",
                content: "Share your organized contact lists with other pilots using the new multi-category export feature.",
                screenshot: UIImage(named: "help_export_contacts"),
                detailedContent: """
                To export contacts (individual or multiple categories):
                
                Single Category Export:
                1. Go to Contacts
                2. Swipe left on any category
                3. Tap "Export"
                4. Choose sharing method
                
                Multi-Category Export (NEW!):
                1. Go to Contacts
                2. Tap "Batch Export" at the bottom
                3. Select which categories to include:
                   • All categories are pre-selected
                   • Uncheck categories you don't want to export
                   • See contact counts for each category
                4. Tap "Export"
                5. Choose sharing method
                
                The exported file:
                • Has a .shipcontacts extension
                • Contains all selected contact information and categories
                • Can be opened directly on another device with the app
                • Preserves category organization
                
                This helps ensure all pilots have access to the same contact information and is perfect for:
                • Team standardization
                • Backup purposes
                • Distributing updated contact lists
                """
            ),
            HelpTopic(
                id: "csv_contacts_import",
                title: "Importing Contacts from CSV",
                content: "Import contact lists from spreadsheets for bulk contact management.",
                screenshot: UIImage(named: "help_csv_contacts"),
                detailedContent: """
                To import contacts from CSV:
                
                1. Create a spreadsheet with contact information
                2. Required columns: Name, Phone
                3. Optional columns: Email, Organization, Role, VHF, Call Sign, Port, Notes
                4. Save as .csv format
                5. Share the CSV file to your app or use Files app to open it
                
                The app will:
                • Automatically detect if it's a contacts CSV or checklist CSV
                • Import contacts to a timestamped "Imported CSV" category
                • Preserve all available contact information
                • Allow you to drag contacts to appropriate categories afterward
                
                This is useful for:
                • Setting up the app with existing contact databases
                • Importing contacts from other systems
                • Bulk contact management
                """
            )
        ]
    )
}
