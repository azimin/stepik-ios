//
//  ControllerQuizWebViewHelper.swift
//  Stepic
//
//  Created by Alexander Karpov on 29.05.16.
//  Copyright © 2016 Alex Karpov. All rights reserved.
//

import Foundation

class ControllerQuizWebViewHelper {
    
    fileprivate var tableView: UITableView
    fileprivate var view: UIView
    fileprivate var countClosure : ((Void) -> Int)
    fileprivate var expectedQuizHeightClosure : ((Void) -> CGFloat)
    fileprivate var noQuizHeightClosure : ((Void) -> CGFloat)
    fileprivate var delegate : QuizControllerDelegate?
    
    fileprivate var optionsCount : Int {
        return countClosure()
    }
    
    fileprivate var expectedQuizHeight : CGFloat {
        return expectedQuizHeightClosure()
    }
    
    fileprivate var heightWithoutQuiz : CGFloat {
        return noQuizHeightClosure()
    }
    
    
    init(tableView: UITableView, view: UIView, countClosure: @escaping ((Void) -> Int), expectedQuizHeightClosure: @escaping ((Void) -> CGFloat), noQuizHeightClosure: @escaping ((Void) -> CGFloat), delegate: QuizControllerDelegate?) {
        self.tableView = tableView
        self.view = view
        self.countClosure = countClosure
        self.expectedQuizHeightClosure = expectedQuizHeightClosure
        self.noQuizHeightClosure = noQuizHeightClosure
        self.delegate = delegate
    }
    
    func initChoicesHeights() {
        self.cellHeights = [Int](repeating: 1, count: optionsCount)
    }
    
    func updateChoicesHeights() {
        initHeightUpdateBlocks()
        self.tableView.reloadData()
        performHeightUpdates()
        self.view.layoutIfNeeded()
    }
    
    fileprivate func initHeightUpdateBlocks() {
        cellHeightUpdateBlocks = []
        for _ in 0 ..< optionsCount {
            cellHeightUpdateBlocks += [{
                return 1
                }]
        }
    }
    
    //Measured in seconds
    let reloadTimeStandardInterval = 0.5
    let reloadTimeout = 5.0
    let noReloadTimeout = 1.0
    
    fileprivate func reloadWithCount(_ count: Int, noReloadCount: Int) {
        if Double(count) * reloadTimeStandardInterval > reloadTimeout {
            return
        }
        if Double(noReloadCount) * reloadTimeStandardInterval > noReloadTimeout {
            return 
        }
        delay(reloadTimeStandardInterval * Double(count), closure: {
            [weak self] in
            if self?.countHeights() == true {
                UIThread.performUI{
                    self?.tableView.reloadData() 
                    if let expectedHeight = self?.expectedQuizHeight, 
                        let noQuizHeight = self?.heightWithoutQuiz {
                        self?.delegate?.needsHeightUpdate(expectedHeight + noQuizHeight, animated: true) 
                    }
                }
                self?.reloadWithCount(count + 1, noReloadCount: 0)
            } else {
                self?.reloadWithCount(count + 1, noReloadCount: noReloadCount + 1)
            }
            })  
    }    
    
    fileprivate func performHeightUpdates() {
        self.reloadWithCount(0, noReloadCount: 0)
    }
    
    fileprivate func countHeights() -> Bool {
        var index = 0
        var didChangeHeight = false
        for updateBlock in cellHeightUpdateBlocks {
            let h = updateBlock()
            if abs(cellHeights[index] - h) > 1 { 
                //                print("changed height of cell \(index) from \(cellHeights[index]) to \(h)")
                cellHeights[index] = h
                didChangeHeight = true
            }
            index += 1
        }
        return didChangeHeight
    }
    
    var cellHeightUpdateBlocks : [((Void)->Int)] = []
    var cellHeights : [Int] = []
}
