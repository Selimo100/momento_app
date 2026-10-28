import SwiftUI

/// Support for iPhone Duo's folding display.
///
/// iPhone Duo presents navigation bars, toolbars and tab bars *vertically* down
/// the side of the display in some poses, and splits the screen across a fold
/// when partially closed.
///
/// Two separate version problems are handled here:
///
/// * **Runtime.** The describing APIs land in iOS 27.0/27.1 while the app
///   deploys back to iOS 26.0, so each call sits behind `#available`.
/// * **Compile time.** Those symbols only exist in the iOS 27 SDK. CI builds on
///   runner images carrying Xcode 26, so the code is additionally gated on
///   `compiler(>=6.4)` — the Swift version Xcode 27 ships. On an older
///   toolchain the helpers below compile to no-ops and the app keeps its
///   ordinary horizontal layout.
enum DuoLayout {
    /// Minimum edge a photo tile should keep so it stays tappable when the
    /// display is split by the fold.
    static let minimumTileEdge: CGFloat = 96

    /// Whether this binary was built with an SDK that knows about iPhone Duo.
    static var isBuiltWithDuoSDK: Bool {
        #if compiler(>=6.4)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Vertical bar awareness

/// Reads whether the system is currently presenting bars vertically.
///
/// `nil` means bars are horizontal — because the pose calls for it, because the
/// OS predates iPhone Duo, or because this build used an older SDK. Custom bar
/// content uses this to swap in a layout that reads well in a narrow strip.
struct VerticalBarEdgeReader<Content: View>: View {
    @ViewBuilder let content: (HorizontalEdge?) -> Content

    var body: some View {
        #if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            ResolvedReader(content: content)
        } else {
            content(nil)
        }
        #else
        content(nil)
        #endif
    }

    #if compiler(>=6.4)
    @available(iOS 27.1, *)
    private struct ResolvedReader<Inner: View>: View {
        @Environment(\.toolbarVerticalEdge) private var verticalEdge
        @ViewBuilder let content: (HorizontalEdge?) -> Inner

        var body: some View {
            content(verticalEdge)
        }
    }
    #endif
}

// MARK: - Toolbar item adaptation

extension ToolbarContent {
    /// Marks an item as important enough to stay out of the overflow menu when
    /// the bar is presented vertically and space is tight.
    @ToolbarContentBuilder
    func duoVisibilityPriority(_ priority: DuoToolbarPriority) -> some ToolbarContent {
        #if compiler(>=6.4)
        if #available(iOS 27.0, *) {
            self.visibilityPriority(priority.resolvedPriority)
        } else {
            self
        }
        #else
        self
        #endif
    }

    /// Keeps an item out of vertical bars when its content only reads correctly
    /// laid out horizontally — for example a custom view with no symbol.
    @ToolbarContentBuilder
    func duoAxisBehavior(_ behavior: DuoAxisBehavior) -> some ToolbarContent {
        #if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            self.axisBehavior(behavior.resolvedBehavior)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

/// Version-independent mirror of `ToolbarItemVisibilityPriority`.
enum DuoToolbarPriority {
    case low, automatic, high

    #if compiler(>=6.4)
    @available(iOS 27.0, *)
    var resolvedPriority: ToolbarItemVisibilityPriority {
        switch self {
        case .low: .low
        case .automatic: .automatic
        case .high: .high
        }
    }
    #endif
}

/// Version-independent mirror of `ToolbarItemAxisBehavior`.
enum DuoAxisBehavior {
    case automatic, horizontalOnly, verticalPreferred

    #if compiler(>=6.4)
    @available(iOS 27.1, *)
    var resolvedBehavior: ToolbarItemAxisBehavior {
        switch self {
        case .automatic: .automatic
        case .horizontalOnly: .horizontalOnly
        case .verticalPreferred: .verticalPreferred
        }
    }
    #endif
}

// MARK: - Sheet placement

extension View {
    /// Asks the system to place a sheet on a given side of the inner display.
    ///
    /// On the inner display a trailing sheet gets a vertical toolbar, while
    /// centred and leading sheets keep a horizontal one.
    @ViewBuilder
    func duoPresentationPlacement(_ placement: DuoSheetPlacement) -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27.0, *) {
            self.presentationPlacement(placement.resolvedPlacement)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

/// Version-independent mirror of `PresentationPlacement`.
enum DuoSheetPlacement {
    case automatic, leading, center, trailing

    #if compiler(>=6.4)
    @available(iOS 27.0, *)
    var resolvedPlacement: PresentationPlacement {
        switch self {
        case .automatic: .automatic
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
    #endif
}

// MARK: - Reserved regions

extension GeometryProxy {
    /// Frames of the regions the system has reserved inside this view — the
    /// fold when the device is partially closed, and the front camera.
    ///
    /// Returns an empty array when there is no folding display, so callers can
    /// treat "no reserved regions" as the normal full-bleed case.
    func duoReservedRegionFrames() -> [CGRect] {
        #if compiler(>=6.4)
        guard #available(iOS 27.1, *) else { return [] }
        // `Kind` has no "all" case, so the two kinds are queried separately:
        // a division is the fold splitting the view, an occlusion is hardware
        // such as the front camera covering it.
        let regions = reservedRegions(kind: .division) + reservedRegions(kind: .occlusion)
        return regions.filter(\.isActive).map(\.frame)
        #else
        return []
        #endif
    }
}
