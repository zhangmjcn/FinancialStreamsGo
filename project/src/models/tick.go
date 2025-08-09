package models

import "time"

// Tick 表示市场行情tick数据
type Tick struct {
	Symbol    string    `json:"symbol"`    // 交易对标识
	Price     float64   `json:"price"`     // 价格
	Volume    float64   `json:"volume"`    // 成交量
	Timestamp time.Time `json:"timestamp"` // 时间戳
	Bid       float64   `json:"bid"`       // 买价
	Ask       float64   `json:"ask"`       // 卖价
	BidVolume float64   `json:"bid_volume"` // 买量
	AskVolume float64   `json:"ask_volume"` // 卖量
}