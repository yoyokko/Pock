//
//  ControlCenterWidget.swift
//  Pock
//
//  Created by Pierluigi Galdi on 16/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

protocol PressableSegmentedControlDelegate: class {
    func didMove(with event: NSEvent, location: NSPoint)
}

class PressableSegmentedControl: NSSegmentedControl {
    
    /// Public
    weak var delegate: PressableSegmentedControlDelegate?
    var didPressAt: ((NSPoint) -> Void)?
    var minimumPressDuration: TimeInterval = 0.55
    
    /// Core
    private var location: NSPoint = .zero
    private var began_time: Date!
    private var timer: Timer?
    private var canMove: Bool = false
    
    override func touchesBegan(with event: NSEvent) {
        super.touchesBegan(with: event)
        began_time = Date()
        location = event.allTouches().first?.location(in: self) ?? .zero
        timer = Timer.scheduledTimer(withTimeInterval: minimumPressDuration, repeats: false, block: { [unowned self] _ in
            self.canMove = true
            self.didPressAt?(self.location)
        })
    }
    
    override func touchesMoved(with event: NSEvent) {
        super.touchesMoved(with: event)
        location = event.allTouches().first?.location(in: self) ?? .zero
        timer?.fire()
        if canMove {
            delegate?.didMove(with: event, location: location)
        }
    }
    
    override func touchesEnded(with event: NSEvent) {
        timer?.invalidate()
        canMove  = false
        location = .zero
        super.touchesEnded(with: event)
    }
}

class ControlCenterWidget: PKWidget {
    
    var identifier: NSTouchBarItem.Identifier = NSTouchBarItem.Identifier.controlCenter
    var customizationLabel: String            = "Control Center".localized
    var view: NSView!
    var keyCodeItems: [CCKeyCode] = []
    
    /// Core
    // Use controlsRaw to find volume and brightness items. Using control will show same icon for both vol(and brightness) up and down in slideableController when only 1 of up/down is enabled
    private var controlsRaw: [ControlCenterItem] {
        return [
            CCSleepItem(parentWidget: self),
            CCLockItem(parentWidget: self),
            CCBrightnessDownItem(parentWidget: self),
            CCBrightnessUpItem(parentWidget: self),
            CCVolumeDownItem(parentWidget: self),
            CCVolumeUpItem(parentWidget: self),
            CCToggleMuteItem(parentWidget: self),
            ] + self.keyCodeItems
    }
    
    private var controls: [ControlCenterItem] {
        return controlsRaw.filter({ $0.enabled })
    }
    private var slideableController: PKSlideableController?
    
    /// Volume items
    public var volumeItems: [ControlCenterItem] {
        return controlsRaw.filter({ $0 is CCVolumeUpItem || $0 is CCVolumeDownItem || $0 is CCToggleMuteItem })
    }
    
    /// Brightness items
    public var brightnessItems: [ControlCenterItem] {
        return controlsRaw.filter({ $0 is CCBrightnessUpItem || $0 is CCBrightnessDownItem })
    }
    
    /// UI
    fileprivate var segmentedControl: PressableSegmentedControl!
    
    required init() {
        
    }
    
    required init(keyboardShortcuts: [NSDictionary]?) {
        for keyShortcut in keyboardShortcuts! {
            let keycodeItem = CCKeyCode(parentWidget: self,
                                        keyCode: keyShortcut.object(forKey: "keyCode") as? CGKeyCode ?? 0,
                                        cmd: keyShortcut.object(forKey: "cmd") as? Bool ?? false ,
                                        alt: keyShortcut.object(forKey: "alt") as? Bool ?? false,
                                        ctrl: keyShortcut.object(forKey:"ctrl") as? Bool ?? false,
                                        shift: keyShortcut.object(forKey:"shift") as? Bool ?? false,
                                        title: keyShortcut.object(forKey:"title") as? String ?? "",
                                        icon: keyShortcut.object(forKey:"icon") as? String ?? "",
                                        conditionApp: keyShortcut.object(forKey: "condition") as? String ?? nil)
            self.keyCodeItems.append(keycodeItem)
        }
        self.load()
    }
    
    func viewDidAppear() {
        NSWorkspace.shared.notificationCenter.addObserver(forName: .shouldReloadControlCenterWidget, object: nil, queue: .main, using: { [weak self] _ in
            self?.load()
        })
    }
    
    private func load() {
        self.initializeSegmentedControl()
        self.view = segmentedControl
    }
    
    private func initializeSegmentedControl() {
        let itemLabels = controls.map({ $0.title }) as [String]
        guard segmentedControl == nil else {
            segmentedControl.segmentCount = controls.count
            controls.enumerated().forEach({ index, con in
                segmentedControl.setWidth(50, forSegment: index)
                if con.icon != nil {
                    segmentedControl.setLabel("", forSegment: index)
                    segmentedControl.setImage(con.icon, forSegment: index)
                } else {
                    segmentedControl.setLabel(con.title, forSegment: index)
                }
                segmentedControl.setWidth(50, forSegment: index)
            })
            return
        }
        segmentedControl = PressableSegmentedControl(labels: itemLabels, trackingMode: .momentary, target: self, action: #selector(tap(_:)))
        segmentedControl.delegate = self
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.autoresizingMask = .width
        controls.enumerated().forEach({ index, con in
            if con.icon != nil {
                segmentedControl.setLabel("", forSegment: index)
                segmentedControl.setImage(con.icon, forSegment: index)
            }
            segmentedControl.setWidth(50, forSegment: index)
        })
        segmentedControl.didPressAt = { [unowned self] location in
            self.longTap(at: location)
        }
    }
    
    @objc private func tap(_ sender: NSSegmentedControl) {
        controls[sender.selectedSegment].action()
    }
    
    // Hard Coded integer causes issue on long tap area when number of items change 
    @objc private func longTap(at location: CGPoint) {
        let index = Int(ceil(location.x / (segmentedControl.frame.width / CGFloat(controls.count)))) - 1
        guard (0..<controls.count).contains(index) else { return }
        segmentedControl.selectedSegment = index
        controls[index].longPressAction()
    }
}

extension ControlCenterWidget {
    func showSlideableController(for item: ControlCenterItem?, currentValue: Float = 0) {
        guard let item = item else { return }
        slideableController = PKSlideableController.load()
        switch item.self {
        case is CCVolumeUpItem, is CCVolumeDownItem, is CCToggleMuteItem:
            slideableController?.set(downItem: CCVolumeDownItem(parentWidget: self), upItem: CCVolumeUpItem(parentWidget: self))
        case is CCBrightnessUpItem, is CCBrightnessDownItem:
            slideableController?.set(downItem: CCBrightnessDownItem(parentWidget: self), upItem: CCBrightnessUpItem(parentWidget: self))
        default:
            return
        }
        slideableController?.set(currentValue: currentValue)
        AppDelegate.default.navController?.push(slideableController!)
    }
}

extension ControlCenterWidget: PressableSegmentedControlDelegate {
    func didMove(with event: NSEvent, location: NSPoint) {
        let slider = slideableController?.touchBar?.item(forIdentifier: NSTouchBarItem.Identifier(rawValue: "SlideItem"))
        slider?.view?.touchesBegan(with: event)
        slider?.view?.touchesMoved(with: event)
        slideableController?.set(initialLocation: location)
    }
}
