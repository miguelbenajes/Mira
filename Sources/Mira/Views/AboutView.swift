import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                if let image = NSImage(named: "eye_logo") {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    // Fallback to symbol if asset not found in bundle
                    Image(systemName: "eye.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                }

                Text("Mira")
                    .font(.system(size: 28, weight: .bold))
                
                Text("Monitor Float Application")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                    .padding(.vertical, 8)
                
                Text("Version 1.0")
                    .font(.body)
                
                Text("© 2026 Miguel Angel Benajes")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(30)
        .frame(width: 350, height: 400)
    }
}
