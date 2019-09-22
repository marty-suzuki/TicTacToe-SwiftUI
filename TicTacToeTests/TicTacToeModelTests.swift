//
//  TicTacToeModelTests.swift
//  TicTacToeTests
//
//  Created by marty-suzuki on 2019/09/22.
//  Copyright © 2019 jp.marty-suzuki. All rights reserved.
//

import Combine
import XCTest
@testable import TicTacToe

class TicTacToeModelTests: XCTestCase {

    private var dependecy: Dependency!

    override func setUp() {
        self.dependecy = Dependency()
    }

    func test_initial_states() {

        XCTAssertNil(dependecy.store.winner)
        XCTAssertEqual(dependecy.store.currentPlayer, .o)
        XCTAssertFalse(dependecy.store.isGameEnded)

        let lines = dependecy.extra.lines
        let expectedBoard = (0..<lines).map { section in
            (0..<lines).map { Address(id: $0 + section * lines, player: nil) }
        }
        XCTAssertEqual(dependecy.store.board, expectedBoard)
    }

    func test_currentPlayer_changes_when_empty_address_tapped() {

        let address = dependecy.store.board[0][0]
        XCTAssertNil(address.player)
        XCTAssertEqual(dependecy.store.currentPlayer, .o)

        dependecy.testTarget.input.handleAddress.send(address)

        XCTAssertEqual(dependecy.store.board[0][0].player, .o)
        XCTAssertEqual(dependecy.store.currentPlayer, .x)
    }

    func test_currentPlayer_does_not_change_when_non_empty_address_tapped() {

        var board = dependecy.store.board
        let address = Address(id: 0, player: .o)
        board[0][0] = address
        dependecy.store.board = board
        XCTAssertEqual(dependecy.store.currentPlayer, .o)

        dependecy.testTarget.input.handleAddress.send(address)

        XCTAssertEqual(dependecy.store.board, board)
        XCTAssertEqual(dependecy.store.currentPlayer, .o)
    }

    func test_winner_is_o() {

        dependecy.extra.winPatterns.forEach { pattern in

            dependecy.testTarget.input.startNewGame.send()

            XCTAssertNil(dependecy.store.winner)
            XCTAssertFalse(dependecy.store.isGameEnded)

            var board = dependecy.store.board
            dependecy.idAndIndexPaths(from: pattern).forEach {
                board[$1.section][$1.row] =  Address(id: $0, player: .o)
            }
            dependecy.store.board = board

            XCTAssertEqual(dependecy.store.winner, .o)
            XCTAssertTrue(dependecy.store.isGameEnded)
        }
    }

    func test_winner_is_x() {

        dependecy.extra.winPatterns.forEach { pattern in

            dependecy.testTarget.input.startNewGame.send()

            XCTAssertNil(dependecy.store.winner)
            XCTAssertFalse(dependecy.store.isGameEnded)

            var board = dependecy.store.board
            dependecy.idAndIndexPaths(from: pattern).forEach {
                board[$1.section][$1.row] =  Address(id: $0, player: .x)
            }
            dependecy.store.board = board

            XCTAssertEqual(dependecy.store.winner, .x)
            XCTAssertTrue(dependecy.store.isGameEnded)
        }
    }

    func test_draw() {

        XCTAssertNil(dependecy.store.winner)
        XCTAssertFalse(dependecy.store.isGameEnded)

        var board = dependecy.store.board
        board[0][0] = Address(id: 0, player: .o)
        board[0][1] = Address(id: 1, player: .o)
        board[0][2] = Address(id: 2, player: .x)
        board[1][0] = Address(id: 3, player: .x)
        board[1][1] = Address(id: 4, player: .x)
        board[1][2] = Address(id: 5, player: .o)
        board[2][0] = Address(id: 6, player: .o)
        board[2][1] = Address(id: 7, player: .o)
        board[2][2] = Address(id: 8, player: .x)
        dependecy.store.board = board

        XCTAssertNil(dependecy.store.winner)
        XCTAssertTrue(dependecy.store.isGameEnded)
    }
}

extension TicTacToeModelTests {
    private typealias Address = TicTacToeModel.Address


    private struct Dependency {

        let store = TicTacToeModel.Store()
        let extra = TicTacToeModel.Extra()
        let testTarget: TicTacToeModel

        init() {
            self.testTarget = TicTacToeModel(input: .init(), store: store, extra: extra)
        }

        func idAndIndexPaths(from array: [Int]) -> [(Int, IndexPath)] {
            let lines = extra.lines
            return array.map {
                let section = $0 / lines
                return ($0, IndexPath(row: $0 - (section * lines), section: section))
            }
        }
    }
}
