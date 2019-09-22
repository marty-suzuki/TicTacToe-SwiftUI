//
//  TicTacToeModel.swift
//  TicTacToe
//
//  Created by marty-suzuki on 2019/09/22.
//  Copyright © 2019 jp.marty-suzuki. All rights reserved.
//

import Combine
import Foundation
import Ricemill

final class TicTacToeModel: Machine<TicTacToeModel.Resolver> {

    enum Player {
        case o
        case x
    }

    struct Address: Identifiable, Hashable {
        let id: Int
        let player: Player?
    }
}

// MARK: - Ricemill Definitions

extension TicTacToeModel {

    struct Input: InputType {
        let handleAddress = PassthroughSubject<Address, Never>()
        let startNewGame = PassthroughSubject<Void, Never>()
    }

    final class Store: StoredOutputType {
        @Published var winner: Player?
        @Published var currentPlayer: Player = .o
        @Published var board: [[Address]] = []
        @Published var isGameEnded = false
    }

    struct Extra: ExtraType {
        let lines: Int = 3
        let winPatterns = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]
    }

    enum Resolver: ResolverType {

        static func polish(input: Publishing<Input>, store: Store, extra: Extra) -> Polished<Store> {
            var cancellables: [AnyCancellable] = []

            // Update board and currentUser
            do {
                let updatedData = input.handleAddress
                    .flatMap { address -> AnyPublisher<([[Address]], Bool), Never> in
                        let indexPathOfID: (Int, [[Address]]) -> IndexPath? = { id, board in
                            board.lazy
                                .enumerated()
                                .compactMap { args in
                                    args.element
                                        .firstIndex { $0.id == id }
                                        .map { IndexPath(row: $0, section: args.offset) }
                                }
                                .first
                        }

                        return indexPathOfID(address.id, store.board)
                            .flatMap { indexPath -> Just<([[Address]], Bool)> in
                                var board = store.board
                                let target = board[indexPath.section][indexPath.row]
                                let shouldChangePlayer: Bool
                                if target.player == nil {
                                    board[indexPath.section][indexPath.row] = Address(id: target.id,
                                                                                      player: store.currentPlayer)
                                    shouldChangePlayer = true
                                } else {
                                    shouldChangePlayer = false
                                }
                                return Just((board, shouldChangePlayer))
                            }
                            .map { $0.eraseToAnyPublisher() } ?? Empty().eraseToAnyPublisher()
                    }
                    .share()

                updatedData
                    .map { $0.0 }
                    .assign(to: \.board, on: store)
                    .store(in: &cancellables)

                updatedData
                    .filter { $0.1 }
                    .map { _ in
                        switch store.currentPlayer {
                        case .o: return .x
                        case .x: return .o
                        }
                    }
                    .assign(to: \.currentPlayer, on: store)
                    .store(in: &cancellables)

                input.startNewGame
                    .merge(with: Just(()))
                    .sink {
                        store.board = (0..<extra.lines).map { section in
                            (0..<extra.lines).map { Address(id: $0 + section * extra.lines, player: nil) }
                        }
                        store.currentPlayer = .o
                    }
                    .store(in: &cancellables)
            }

            // Update winner
            store.$board
                .map { board in
                    enum State {
                        case initial
                        case winner(Player)
                    }

                    let addressOfID: (Int, [[Address]]) -> Address? = { id, board in
                        board.lazy
                            .enumerated()
                            .compactMap { $0.element.first { $0.id == id } }
                            .first
                    }

                    return extra.winPatterns.lazy
                        .compactMap { pattern in
                            pattern.reduce(.initial) { state, id -> State? in
                                switch state {
                                case .initial?:
                                    return addressOfID(id, board).flatMap { $0.player.map(State.winner) }
                                case let .winner(winner)?:
                                    if let player = addressOfID(id, board)?.player, winner == player {
                                        return .winner(player)
                                    } else {
                                        return nil
                                    }
                                case .none:
                                    return nil
                                }
                            }
                        }
                        .first
                        .flatMap { state in
                            switch state {
                            case .initial: return nil
                            case let .winner(player): return player
                            }
                        }
                }
                .assign(to: \.winner, on: store)
                .store(in: &cancellables)

            // Handle game ended
            do {
                let trigger1 = store.$winner
                    .map { $0 != nil }

                let trigger2 = store.$board
                    .flatMap { board -> AnyPublisher<Bool, Never> in
                        let hasEmpty = board.first { $0.first { $0.player == nil } != nil } != nil
                        return hasEmpty ? Empty().eraseToAnyPublisher() : Just(true).eraseToAnyPublisher()
                    }

                trigger1
                    .merge(with: trigger2)
                    .assign(to: \.isGameEnded, on: store)
                    .store(in: &cancellables)
            }

            return Polished(cancellables: cancellables)
        }
    }
}
