package models

import "time"

// Kline 表示K线数据
type Kline struct {
	Symbol    string    `json:"symbol"`     // 交易对标识
	Open      float64   `json:"open"`       // 开盘价
	High      float64   `json:"high"`       // 最高价
	Low       float64   `json:"low"`        // 最低价
	Close     float64   `json:"close"`      // 收盘价
	Volume    float64   `json:"volume"`     // 成交量
	StartTime time.Time `json:"start_time"` // K线开始时间
	EndTime   time.Time `json:"end_time"`   // K线结束时间
	Interval  string    `json:"interval"`   // K线时间间隔 (1m, 5m, 15m, 1h, 1d等)
}