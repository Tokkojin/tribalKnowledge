package grifts

import (
	"github.com/gobuffalo/buffalo"
	"github.com/narrative/backend/actions"
)

func init() {
	buffalo.Grifts(actions.App())
}
