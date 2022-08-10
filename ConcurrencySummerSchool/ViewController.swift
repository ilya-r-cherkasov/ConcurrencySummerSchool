//
//  ViewController.swift
//  ConcurrencySummerSchool
//
//  Created by Ilya Cherkasov on 09.08.2022.
//

import UIKit
import Foundation

class ViewController: UIViewController {

    var timer: Timer?
    let url = URL(string: "https://picsum.photos/500")!
    let serialQueue = DispatchQueue(label: "serialQueue")
    let concurrentQueue = DispatchQueue(label: "concurrentQueue", qos: .default, attributes: .concurrent)
    let operationQueue = OperationQueue()
    let semaphore = DispatchSemaphore(value: 2)
    let group = DispatchGroup()

    let stackView = UIStackView(frame: UIScreen.main.bounds)
    lazy var performButton = makePerformButton()

    var i = 0

    lazy var imageView1 = makeImageView()
    lazy var imageView2 = makeImageView()
    lazy var imageView3 = makeImageView()
    lazy var imageView4 = makeImageView()
    lazy var imageView5 = makeImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 3
        view.addSubview(stackView)
        view.addSubview(performButton)

        NSLayoutConstraint.activate([
            performButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            performButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        stackView.addArrangedSubview(imageView1)
        stackView.addArrangedSubview(imageView2)
        stackView.addArrangedSubview(imageView3)
        stackView.addArrangedSubview(imageView4)
        stackView.addArrangedSubview(imageView5)

    }

    func makeImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .gray
        return imageView
    }

    func makeSpinner() -> UIActivityIndicatorView {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.center = CGPoint(
            x: UIScreen.main.bounds.midX,
            y: UIScreen.main.bounds.midY
        )
        spinner.color = .red
        return spinner
    }

    func makePerformButton() -> UIButton {
        let button = UIButton()
        button.setTitle("Исполнить", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.blue, for: .normal)
        button.setTitleColor(.green, for: .highlighted)
        button.addTarget(self, action: #selector(makeSomething), for: .touchUpInside)
        return button
    }

    @objc
    func makeSomething() {
        testOperationQueue()
    }

    func makeHeavyTask() {
        (0...100000).forEach { num in
            print(num)
        }
    }

    func testThreads() {
        let thread = Thread { [weak self] in
            self?.makeHeavyTask()
        }
        thread.start()
    }

    func testSerialQueues() {
        serialQueue.async {
            (0...20).forEach { _ in print("❤️") }
        }
        serialQueue.async {
            (0...20).forEach { _ in print("😘") }
        }
    }

    func testConcurrentQueue() {
        concurrentQueue.async {
            (0...20).forEach { _ in print("❤️") }
        }
        concurrentQueue.async {
            (0...20).forEach { _ in print("😘") }
        }
    }

    func testSaticConcurrentPerfome() {
        DispatchQueue.global(qos: .default).async {
            DispatchQueue.concurrentPerform(iterations: 200000) { num in
                print(num)
                print(Thread.current)
            }
        }
    }

    func testDispatchWorkItem() {
        let task = DispatchWorkItem {
            print(Thread.current)
            print("testDispatchWorkItem")
            print("-------")
        }
        serialQueue.async(execute: task)
        task.notify(queue: .main) {
            print(Thread.current)
            print("MainQueue notified")
            print("-------")
        }
        task.notify(queue: concurrentQueue) {
            print(Thread.current)
            print("concurrentQueue notified")
            print("-------")
        }
        task.notify(queue: serialQueue) {
            print(Thread.current)
            print("serialQueue notified")
            print("-------")
        }
    }

    //GCD не умеет выполнять во время выполнения таски

    func testCancel() {
        let item = DispatchWorkItem { [weak self] in
            self?.makeHeavyTask()
        }
        concurrentQueue.async(execute: item)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("Cancel")
            item.cancel()
        }
    }

    // Семафоры

    func testSemaphores() {
        concurrentQueue.async { [weak self] in
            self?.semaphore.wait()
            print("task 1")
            sleep(2)
            self?.semaphore.signal()
        }
        concurrentQueue.async { [weak self] in
            self?.semaphore.wait()
            print("task 2")
            sleep(2)
            self?.semaphore.signal()
        }
        concurrentQueue.async { [weak self] in
            self?.semaphore.wait()
            print("task 3")
            sleep(2)
            self?.semaphore.signal()
        }
    }

    func testDispatchGroup1() {
        concurrentQueue.async(group: group) {
            (0...1000).forEach { _ in print("❤️") }
        }
        concurrentQueue.async(group: group) {
            (0...100).forEach { _ in print("😘") }
        }
        group.notify(queue: .main) {
            print("Main queue notified")
        }
    }

    func testDispatchGroup2() {
        group.enter()
        concurrentQueue.async { [weak self] in
            (0...1000).forEach { _ in print("❤️") }
            self?.group.leave()
        }
        group.enter()
        concurrentQueue.async(group: group) { [weak self] in
            (0...100).forEach { _ in print("😘") }
            self?.group.leave()
        }
        group.notify(queue: .main) {
            print("Main queue notified")
        }
    }

    func testDispatchGroup3() {
        group.enter()
        concurrentQueue.async { [weak self] in
            (0...1000).forEach { _ in print("❤️") }
            self?.group.leave()
        }
        group.enter()
        concurrentQueue.async(group: group) { [weak self] in
            (0...100).forEach { _ in print("😘") }
            self?.group.leave()
        }
        group.wait()
        print("Done!")
    }

    func barrierTask() {
        concurrentQueue.async {
            sleep(1)
            print("task 1")
        }
        concurrentQueue.async {
            sleep(2)
            print("task 2")
        }
        concurrentQueue.async(flags: .barrier) {
            sleep(5)
            print("task 3")
        }
        concurrentQueue.async {
            sleep(2)
            print("task 4")
        }
        concurrentQueue.async {
            sleep(2)
            print("task 5")
        }
    }

    func testOperationQueue() {
        let operation = MyOperation()
        operationQueue.addOperation(operation)
        operation.cancel()
    }

}

class MyOperation: Operation {

    override func main() {
        (0...10000).forEach { num in
            if isCancelled {
                return
            }
            print(num.description)
        }
    }

}
