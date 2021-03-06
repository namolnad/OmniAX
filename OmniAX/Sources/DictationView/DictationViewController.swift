//
//  DictationViewController.swift
//  OmniAX
//
//  Created by Dan Loman on 10/26/17.
//  Copyright © 2017 Dan Loman. All rights reserved.
//

import UIKit
import Speech

public protocol DictationDelegate: class {
    func dispatch(output: Output<String>)
}

final class DictationViewController: UIViewController {
    private(set) var dictationView: DictationView = ._init() {
        $0.dictateButton.addTarget(self, action: #selector(didTapDictate(sender:)), for: .touchUpInside)
    }

    fileprivate lazy var dictationManager: DictationManager = .init()
    
    private var outputManager: DictationReferenceManager = .init()

    override func loadView() {
        view = dictationView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dictationManager.output = { [weak self] in
            switch $0 {
            case .loading(let loading):
                self?.dictationView.show(loading: loading)
            case .failure:
                self?.dictationView.show(loading: false)
            case .success:
                break
            }
            self?.outputManager.dispatch(output: $0)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        checkAccess()
    }

    func add(delegate: DictationDelegate?) -> ManagedReference {
        return outputManager.add(WrappedHashable(delegate as AnyObject))
    }

    @objc private func didTapDictate(sender: UIButton) {
        dictationManager.toggleDictation()
    }

    private func checkAccess() {
        let status = SFSpeechRecognizer.authorizationStatus()

        guard status == .notDetermined else {
            return dictationView.dictateButton.isEnabled = status == .authorized
        }

        SFSpeechRecognizer.requestAuthorization { state in
            OperationQueue.main.addOperation { [weak self] in
                self?.dictationView.dictateButton.isEnabled = state == .authorized
            }
        }
    }
}

extension AX {
    fileprivate static let dictationViewController: DictationViewController = .init()

    static func dictationInputAccessoryView<T: DictationDelegate>(parent: UIViewController?, delegate: T?) -> (UIView, ManagedReference) {
        var width: CGFloat = UIScreen.main.bounds.width
        
        let controller = AX.dictationViewController

        controller.view.removeFromSuperview()

        if let parent = parent {
            parent.addChild(controller)
            controller.didMove(toParent: parent)

            width = parent.view.bounds.width
        }

        controller.view.frame = CGRect(
            origin: .zero,
            size: CGSize(
                width: width,
                height: 60
            )
        )

        return (controller.view, controller.add(delegate: delegate))
    }
}
