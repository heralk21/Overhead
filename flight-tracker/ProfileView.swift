import PhotosUI
import SwiftUI
import UIKit

/// Large title + account photo. No dimming gradient — the map stays visible.
struct MapAccountHeader: View {
    let photo: UIImage?
    let onAccount: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Overhead")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.45), radius: 8, y: 1)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button(action: onAccount) {
                ProfileAvatarView(image: photo, side: 36)
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .accessibilityLabel("Account")
            .accessibilityHint("Name, photo, and aircraft cards")
        }
        .padding(.horizontal, 20)
        .padding(.top, 0)
        .padding(.bottom, 6)
    }
}

struct ProfileAvatarView: View {
    let image: UIImage?
    var side: CGFloat = 36

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color(white: 0.38))
            }
        }
        .frame(width: side, height: side)
        .clipShape(Circle())
        .contentShape(Circle())
        .accessibilityHidden(true)
    }
}

struct ProfileView: View {
    @ObservedObject var profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    NavigationLink {
                        EditProfileView(profile: profile)
                    } label: {
                        identityRow
                    }
                }

                Section("Collection") {
                    if profile.cards.isEmpty {
                        Text("Identify a nearby aircraft to add its type here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            ForEach(profile.cards) { card in
                                Button {
                                    path.append(card)
                                } label: {
                                    PlaneCollectibleCard(card: card)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(card.fullName), spotted \(card.spotCount) times")
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                accountTopBar
            }
            .navigationDestination(for: PlaneCard.self) { card in
                PlaneCardDetailView(card: card)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var accountTopBar: some View {
        ZStack {
            Text("Account")
                .font(.headline)
                .foregroundStyle(.white)
            HStack {
                Spacer(minLength: 0)
                CloseButton(action: { dismiss() })
                    .padding(.trailing, CardChrome.closeBorderInset)
            }
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }

    private var identityRow: some View {
        HStack(spacing: 14) {
            ProfileAvatarView(image: profile.photo, side: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(profile.displayName.trimmingCharacters(in: .whitespaces).isEmpty
                     ? "Your Name"
                     : profile.displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(identitySubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    private var identitySubtitle: String {
        let n = profile.spots.count
        if n == 0 { return "Tap to edit profile" }
        if n == 1 { return "1 aircraft spotted" }
        return "\(n) aircraft spotted"
    }
}

struct EditProfileView: View {
    @ObservedObject var profile: UserProfile
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                        ProfileAvatarView(image: profile.photo, side: 84)
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 22))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, Color.accentColor)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(profile.photo == nil ? "Add profile photo" : "Change profile photo")
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section {
                TextField("Name", text: $profile.displayName, prompt: Text("Your name"))
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Personal Info")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: pickerItem) { _, item in
            Task { await applyPhoto(item) }
        }
    }

    private func applyPhoto(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else { return }
        profile.photo = image.squaredAvatar()
    }
}

struct PlaneCardDetailView: View {
    let card: PlaneCard

    var body: some View {
        List {
            Section {
                PlaneCollectibleCard(card: card, featured: true)
                    .frame(maxWidth: 260)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
            }

            Section {
                LabeledContent("Type", value: card.fullName)
                LabeledContent("Spotted", value: spotSummary)
            }

            Section("Airlines") {
                ForEach(card.airlines) { airline in
                    HStack(spacing: 12) {
                        AirlineLogoView(callsign: airline.sampleCallsign, size: 32)
                        Text(airline.name)
                        Spacer()
                        Text("\(airline.count)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(airline.name), \(airline.count) \(airline.count == 1 ? "spot" : "spots")")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(card.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var spotSummary: String {
        card.spotCount == 1 ? "Once" : "\(card.spotCount) times"
    }
}

/// Dummy collectible — the pasted plate, nothing drawn on top.
struct PlaneCollectibleCard: View {
    let card: PlaneCard
    var featured: Bool = false

    var body: some View {
        Group {
            if let art = CollectibleCardArt.assetName(for: card.familyId) {
                Image(art)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(maxWidth: featured ? 280 : .infinity)
    }
}

enum CollectibleCardArt {
    static func assetName(for familyId: String) -> String? {
        let id = familyId.lowercased()
        if id.contains("b737") { return "collectible_b737" }
        if id.contains("b777") { return "collectible_b777" }
        if id.contains("a380") { return "collectible_a380" }
        return nil
    }
}

private extension UIImage {
    func squaredAvatar(maxDimension: CGFloat = 640) -> UIImage {
        let minSide = min(size.width, size.height)
        guard minSide > 0 else { return self }
        let crop = CGRect(
            x: (size.width - minSide) / 2,
            y: (size.height - minSide) / 2,
            width: minSide,
            height: minSide
        )
        let scale = self.scale
        let scaledCrop = CGRect(
            x: crop.origin.x * scale,
            y: crop.origin.y * scale,
            width: crop.width * scale,
            height: crop.height * scale
        )
        guard let cg = cgImage?.cropping(to: scaledCrop) else { return self }
        let square = UIImage(cgImage: cg, scale: scale, orientation: imageOrientation)
        let target = min(maxDimension, minSide)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: target, height: target), format: format)
            .image { _ in
                square.draw(in: CGRect(origin: .zero, size: CGSize(width: target, height: target)))
            }
    }
}
