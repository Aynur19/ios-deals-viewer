//
//  DealsView.swift
//  DealsViewer
//
//  Created by Aynur Nasybullin on 27.03.2024.
//

import SwiftUI
import Combine

struct DealsView: View {
    @StateObject var provider = DealsViewModel.shared
    
    @State private var isAsc = true
    @State private var sortKey = DealsSortKey.updatedOn
    @State private var sortKeyOrder: [SortKeyOrder]
    
    private let preferenceName = "scrollOffset"
    @State private var yOffset: CurrentValueSubject<CGFloat, Never>
    @State private var publisher: AnyPublisher<CGFloat, Never>
    
    init() {
        sortKeyOrder = [.init(key: DealsSortKey.updatedOn.rawValue, ascending: true)]
        
        let yOffset = CurrentValueSubject<CGFloat, Never>(0)
        self.publisher = yOffset
            .debounce(for: .seconds(0.2), scheduler: DispatchQueue.main)
            .dropFirst()
            .eraseToAnyPublisher()
        self.yOffset = yOffset
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    headers(width: 200)
                        .padding(.horizontal, 24)
                    
                    dealsList
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                    
                    footer
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    viewHeader
                }
            }
        }
    }
    
    private var viewHeader: some View {
        VStack {
            Text("Deals")
                .font(.headline)
        }
    }
    
    private func headers(width: CGFloat) -> some View {
        return VStack {
            Divider()
            HStack {
                header("Instrument", currentSortKey: .instrument, width: width * 0.3)
                    .frame(alignment: .center)
                
                Spacer()
                header("Price", currentSortKey: .price, width: width * 0.15)
                    .frame(alignment: .trailing)
                
                Spacer()
                header("Amount", currentSortKey: .amount, width: width * 0.3)
                    .frame(alignment: .trailing)
                
                Spacer()
                header("Side", currentSortKey: .side, width: width * 0.2)
                    .frame(alignment: .trailing)
            }
            
            Divider()
        }
    }
    
    private func header(_ name: String, currentSortKey: DealsSortKey, width: CGFloat) -> some View {
        sortLabel(name, currentSortKey)
            .labelStyle(TitleAndIconLabelStyle())
            .onTapGesture { updateSort(currentSortKey) }
    }
    
    @ViewBuilder
    private func sortLabel(_ name: String, _ currentSortKey: DealsSortKey) -> some View {
        if sortKey == currentSortKey {
            Label(name, systemImage: isAsc ? "arrow.up" : "arrow.down")
        } else {
            Text(name)
        }
    }
    
    private var dealsList: some View {
        VStack {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                
                ScrollView {
                    LazyVStack {
                        ForEach(provider.deals) { item in
                            dealRow(item, width: width)
                            Divider()
                        }
                    }
                    .background {
                        GeometryReader {
                            Color.clear.preference(
                                key: ScrollViewOffsetPreferenceKey.self,
                                value: -$0.frame(in: .named(preferenceName)).origin.y
                            )
                        }
                    }
                }
                .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) {
                    yOffset.send($0)
                }
                .onReceive(publisher) { offset in
                    loadDeals(height, offset: offset)
                }
            }
        }
    }
    
    private func dealRow(_ deal: DealViewDto, width: CGFloat) -> some View {
        VStack {
            HStack(spacing: 0) {
                Text(deal.instrumentStr)
                    .frame(width: width * 0.3, alignment: .leading)
                Text(deal.priceStr)
                    .frame(width: width * 0.2, alignment: .trailing)
                Text(deal.amountStr)
                    .frame(width: width * 0.3, alignment: .trailing)
                Text(deal.side.str)
                    .frame(width: width * 0.2, alignment: .trailing)
                    .foregroundStyle(deal.side == .sell ? .red : .green)
            }
        }
    }
    
    private var footer: some View {
        VStack(alignment: .leading) {
            Text("DB records: \(provider.dbRecordsCount)")
            Text("Memory objects: \(provider.deals.count)")
        }
        .font(.footnote)
    }
}


extension DealsView {
    private func loadDeals(_ height: CGFloat, offset: CGFloat)  {
        Task {
            await provider.load(height: height, yOffset: offset)
        }
    }
    
    private func updateSort(_ currentSortKey: DealsSortKey) {
        if sortKey != currentSortKey {
            sortKey = currentSortKey
            isAsc = true
        } else {
            isAsc.toggle()
        }
        
        Task {
            await provider.updateSort(sortKey, isAsc: isAsc)
        }
    }
}
