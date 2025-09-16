import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var selectedLanguage = "en"
    @State private var showingBackupSheet = false
    @State private var showingRestoreSheet = false
    
    var body: some View {
        NavigationView {
            List {
                // Notifications Section
                Section("Notifications") {
                    Toggle("Rent Due Reminders", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        HStack {
                            Text("Reminder Schedule")
                            Spacer()
                            Text("3, 1 days before & on due date")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                
                // Language Section
                Section("Language") {
                    Picker("Language", selection: $selectedLanguage) {
                        Text("English").tag("en")
                        Text("简体中文").tag("zh-Hans")
                        Text("繁體中文").tag("zh-Hant")
                    }
                }
                
                // Data Management Section
                Section("Data Management") {
                    Button(action: { showingBackupSheet = true }) {
                        HStack {
                            Image(systemName: "arrow.up.doc")
                                .foregroundColor(.blue)
                            Text("Create Backup")
                            Spacer()
                        }
                    }
                    
                    Button(action: { showingRestoreSheet = true }) {
                        HStack {
                            Image(systemName: "arrow.down.doc")
                                .foregroundColor(.green)
                            Text("Restore Backup")
                            Spacer()
                        }
                    }
                }
                
                // App Information Section
                Section("App Information") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Support Section
                Section("Support") {
                    Button("Contact Support") {
                        // TODO: Implement contact support
                    }
                    
                    Button("Privacy Policy") {
                        // TODO: Show privacy policy
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingBackupSheet) {
                BackupView()
            }
            .sheet(isPresented: $showingRestoreSheet) {
                RestoreView()
            }
        }
    }
}

struct BackupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isCreatingBackup = false
    @State private var backupMessage = ""
    @State private var showingShareSheet = false
    @State private var backupURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "arrow.up.doc.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Create Backup")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Create a backup of all your rental data including properties, contracts, payments, and expenses.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                if isCreatingBackup {
                    ProgressView("Creating backup...")
                        .padding()
                } else if !backupMessage.isEmpty {
                    Text(backupMessage)
                        .foregroundColor(.green)
                        .padding()
                }
                
                Spacer()
                
                Button("Create Backup") {
                    createBackup()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCreatingBackup)
                
                if let backupURL = backupURL {
                    Button("Share Backup File") {
                        showingShareSheet = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let backupURL = backupURL {
                    ShareSheet(items: [backupURL])
                }
            }
        }
    }
    
    private func createBackup() {
        isCreatingBackup = true
        backupMessage = ""
        
        DispatchQueue.global(qos: .userInitiated).async {
            let url = CoreDataService.shared.createBackup()
            
            DispatchQueue.main.async {
                isCreatingBackup = false
                
                if let url = url {
                    backupURL = url
                    backupMessage = "Backup created successfully!"
                } else {
                    backupMessage = "Failed to create backup. Please try again."
                }
            }
        }
    }
}

struct RestoreView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isRestoring = false
    @State private var restoreMessage = ""
    @State private var showingFilePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Restore Backup")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Restore your rental data from a previously created backup file. This will replace all current data.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                if isRestoring {
                    ProgressView("Restoring backup...")
                        .padding()
                } else if !restoreMessage.isEmpty {
                    Text(restoreMessage)
                        .foregroundColor(restoreMessage.contains("successfully") ? .green : .red)
                        .padding()
                }
                
                Spacer()
                
                Button("Select Backup File") {
                    showingFilePicker = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRestoring)
            }
            .padding()
            .navigationTitle("Restore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.database],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            restoreBackup(from: url)
            
        case .failure(let error):
            restoreMessage = "Failed to select file: \(error.localizedDescription)"
        }
    }
    
    private func restoreBackup(from url: URL) {
        isRestoring = true
        restoreMessage = ""
        
        DispatchQueue.global(qos: .userInitiated).async {
            let success = CoreDataService.shared.restoreFromBackup(url)
            
            DispatchQueue.main.async {
                isRestoring = false
                
                if success {
                    restoreMessage = "Backup restored successfully! Please restart the app."
                } else {
                    restoreMessage = "Failed to restore backup. Please check the file and try again."
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
}
