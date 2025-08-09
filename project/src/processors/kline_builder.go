package processors

import (
	"financialstreams/src/models"
	"sync"
	"time"
)

// KlineBuilder 从tick数据构建K线的构建器
type KlineBuilder struct {
	tickChan   chan *models.Tick
	klineChan  chan *models.Kline
	interval   time.Duration
	currentBar map[string]*models.Kline // 按symbol存储当前正在构建的K线
	mu         sync.RWMutex
}

// NewKlineBuilder 创建新的K线构建器
func NewKlineBuilder(interval time.Duration) *KlineBuilder {
	return &KlineBuilder{
		tickChan:   make(chan *models.Tick, 1000),
		klineChan:  make(chan *models.Kline, 100),
		interval:   interval,
		currentBar: make(map[string]*models.Kline),
	}
}

// Build 从tick构建K线
func (b *KlineBuilder) Build() {
	ticker := time.NewTicker(b.interval)
	defer ticker.Stop()

	for {
		select {
		case tick := <-b.tickChan:
			b.updateKline(tick)
		case <-ticker.C:
			b.closeCurrentBars()
		}
	}
}

// updateKline 使用tick更新K线
func (b *KlineBuilder) updateKline(tick *models.Tick) {
	b.mu.Lock()
	defer b.mu.Unlock()

	kline, exists := b.currentBar[tick.Symbol]
	if !exists {
		// 创建新K线
		kline = &models.Kline{
			Symbol:    tick.Symbol,
			Open:      tick.Price,
			High:      tick.Price,
			Low:       tick.Price,
			Close:     tick.Price,
			Volume:    tick.Volume,
			StartTime: b.getIntervalStart(tick.Timestamp),
			Interval:  b.getIntervalString(),
		}
		b.currentBar[tick.Symbol] = kline
	} else {
		// 更新现有K线
		if tick.Price > kline.High {
			kline.High = tick.Price
		}
		if tick.Price < kline.Low {
			kline.Low = tick.Price
		}
		kline.Close = tick.Price
		kline.Volume += tick.Volume
	}
}

// closeCurrentBars 关闭当前K线并发送
func (b *KlineBuilder) closeCurrentBars() {
	b.mu.Lock()
	defer b.mu.Unlock()

	now := time.Now()
	for symbol, kline := range b.currentBar {
		kline.EndTime = now
		b.klineChan <- kline
		delete(b.currentBar, symbol)
	}
}

// getIntervalStart 获取K线开始时间
func (b *KlineBuilder) getIntervalStart(t time.Time) time.Time {
	return t.Truncate(b.interval)
}

// getIntervalString 获取间隔字符串表示
func (b *KlineBuilder) getIntervalString() string {
	switch b.interval {
	case time.Minute:
		return "1m"
	case 5 * time.Minute:
		return "5m"
	case 15 * time.Minute:
		return "15m"
	case time.Hour:
		return "1h"
	case 24 * time.Hour:
		return "1d"
	default:
		return b.interval.String()
	}
}

// GetTickChannel 获取tick输入通道
func (b *KlineBuilder) GetTickChannel() chan<- *models.Tick {
	return b.tickChan
}

// GetKlineChannel 获取K线输出通道
func (b *KlineBuilder) GetKlineChannel() <-chan *models.Kline {
	return b.klineChan
}