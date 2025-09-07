
import SwiftUI

struct LockedView: View {
    var onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("KharchaMitra is Locked")
                .font(.title2)
                .fontWeight(.semibold)
            Button("Unlock", systemImage: "faceid", action: onUnlock)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    LockedView(onUnlock: {})
}
