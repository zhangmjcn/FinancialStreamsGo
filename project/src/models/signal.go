package models

import "time"

// SignalType 信号类型
type SignalType string

const (
	SignalBuy  SignalType = "BUY"  // 买入信号
	SignalSell SignalType = "SELL" // 卖出信号
	SignalHold SignalType = "HOLD" // 持有信号
)

// Signal 表示交易信号
type Signal struct {
	Symbol    string     `json:"symbol"`    // 交易对标识
	Type      SignalType `json:"type"`      // 信号类型
	Price     float64    `json:"price"`     // 信号价格
	Volume    float64    `json:"volume"`    // 建议交易量
	Strength  float64    `json:"strength"`  // 信号强度 (0-1)
	Source    string     `json:"source"`    // 信号来源/策略名称
	Timestamp time.Time  `json:"timestamp"` // 信号生成时间
	Metadata  map[string]interface{} `json:"metadata,omitempty"` // 附加元数据
}