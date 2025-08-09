package processors

import (
	"financialstreams/src/models"
	"log"
)

// TickProcessor 处理tick数据的处理器
type TickProcessor struct {
	inputChan  chan *models.Tick
	outputChan chan *models.Tick
}

// NewTickProcessor 创建新的tick处理器
func NewTickProcessor() *TickProcessor {
	return &TickProcessor{
		inputChan:  make(chan *models.Tick, 1000),
		outputChan: make(chan *models.Tick, 1000),
	}
}

// Process 处理tick数据
func (p *TickProcessor) Process() {
	for tick := range p.inputChan {
		// 这里实现tick数据的处理逻辑
		// 例如: 数据验证、标准化、过滤等
		
		if p.validateTick(tick) {
			p.outputChan <- tick
		}
	}
}

// validateTick 验证tick数据有效性
func (p *TickProcessor) validateTick(tick *models.Tick) bool {
	if tick.Price <= 0 || tick.Volume < 0 {
		log.Printf("Invalid tick data: %+v", tick)
		return false
	}
	return true
}

// GetInputChannel 获取输入通道
func (p *TickProcessor) GetInputChannel() chan<- *models.Tick {
	return p.inputChan
}

// GetOutputChannel 获取输出通道
func (p *TickProcessor) GetOutputChannel() <-chan *models.Tick {
	return p.outputChan
}