// MomentumEngine.swift
import Foundation
import CoreVideo
import CoreGraphics

enum ScrollPhase: Int64 {
    case began    = 1
    case changed  = 2
    case ended    = 4
    case momentum = 8
}

class MomentumEngine {

    static let shared = MomentumEngine()

    var onScrollDelta: ((_ deltaY: Double, _ deltaX: Double, _ phase: ScrollPhase) -> Void)?

    private var velocityY: Double = 0
    private var velocityX: Double = 0
    private var displayLink: CVDisplayLink?
    private var isRunning = false
    private var sentBegan = false
    private var inMomentumPhase = false
    private let lock = NSLock()

    private init() {}

    func injectScroll(deltaY: Double, deltaX: Double) {
        let settings = SettingsModel.shared
        guard settings.isEnabled else { return }

        let direction: Double = settings.reverseDirection ? -1 : 1
        let multiplier = settings.speed.multiplier

        lock.lock()
        if settings.isMomentumEnabled {
            velocityY += deltaY * direction * multiplier * 8.0
            velocityX += deltaX * direction * multiplier * 8.0
            inMomentumPhase = false
        } else {
            // Direct pass-through when smoothness is off
            let dy = deltaY * direction * multiplier * 3.0
            let dx = deltaX * direction * multiplier * 3.0
            lock.unlock()
            onScrollDelta?(dy, dx, .changed)
            return
        }
        lock.unlock()

        startIfNeeded()
    }

    private func startIfNeeded() {
        guard !isRunning else { return }
        isRunning = true
        sentBegan = false

        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        guard let dl = displayLink else { return }
        CVDisplayLinkSetOutputCallback(dl, displayLinkCallback, Unmanaged.passUnretained(self).toOpaque())
        CVDisplayLinkStart(dl)
    }

    private func stop() {
        guard isRunning else { return }
        if let dl = displayLink { CVDisplayLinkStop(dl) }
        displayLink = nil
        isRunning = false
        velocityY = 0
        velocityX = 0
        inMomentumPhase = false
        sentBegan = false
    }

    fileprivate func onFrame() {
        let settings = SettingsModel.shared

        lock.lock()
        let friction = settings.frictionCoefficient
        let dy = velocityY
        let dx = velocityX
        velocityY *= friction
        velocityX *= friction
        let stillMoving = abs(velocityY) > 0.5 || abs(velocityX) > 0.5
        lock.unlock()

        if abs(dy) > 0.5 || abs(dx) > 0.5 {
            let phase: ScrollPhase
            if !sentBegan {
                phase = .began
                sentBegan = true
            } else if inMomentumPhase {
                phase = .momentum
            } else {
                phase = .changed
            }
            if !inMomentumPhase && abs(dy) < 12.0 {
                inMomentumPhase = true
            }
            onScrollDelta?(dy, dx, phase)
        } else if sentBegan {
            onScrollDelta?(0, 0, .ended)
            DispatchQueue.main.async { self.stop() }
        } else if !stillMoving {
            DispatchQueue.main.async { self.stop() }
        }
    }
}

private func displayLinkCallback(
    displayLink: CVDisplayLink,
    inNow: UnsafePointer<CVTimeStamp>,
    inOutputTime: UnsafePointer<CVTimeStamp>,
    flagsIn: CVOptionFlags,
    flagsOut: UnsafeMutablePointer<CVOptionFlags>,
    context: UnsafeMutableRawPointer?
) -> CVReturn {
    guard let context else { return kCVReturnSuccess }
    Unmanaged<MomentumEngine>.fromOpaque(context).takeUnretainedValue().onFrame()
    return kCVReturnSuccess
}
