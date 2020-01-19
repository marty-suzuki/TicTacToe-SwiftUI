//
//  GameView.swift
//  TicTacToe
//
//  Created by marty-suzuki on 2019/09/22.
//  Copyright © 2019 jp.marty-suzuki. All rights reserved.
//

import SwiftUI

struct GameView: View {

    @ObservedObject var viewModel = TicTacToeModel(input: .init(), store: .init(), extra: .init())

    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 5) {
                ForEach(viewModel.output.board, id: \.self) { line in
                    HStack(spacing: 5) {
                        ForEach(line, id: \.self) { address in
                            (address.player.map {
                                AnyView(Text($0.text).font(.system(size: 50)))
                            } ?? AnyView(
                                Button(action: { self.viewModel.input.handleAddress.send(address) }) {
                                    Text("")
                                        .frame(width: 80, height: 80)
                                        .contentShape(Rectangle())
                                })
                            )
                            .frame(width: 80, height: 80)
                            .background(Color.white)
                        }
                    }
                }
            }
            .background(Color.black)
            Text("Current Player: \(viewModel.output.currentPlayer.text)")
        }
        .alert(isPresented: viewModel.output.isGameEnded) {
            Alert(title: Text("\(viewModel.output.winner.map { $0.text + " win!" } ?? "Draw")"),
                  dismissButton: .default(Text("New Game")) { self.viewModel.input.startNewGame.send() })
        }
    }
}

extension TicTacToeModel.Player {

    var text: String {
        switch self {
        case .o: return "⭕"
        case .x: return "❌"
        }
    }
}
