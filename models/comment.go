package models

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/markbates/pop"
	"github.com/markbates/validate"
	"github.com/markbates/validate/validators"
	"github.com/satori/go.uuid"
)

type Comment struct {
	ID        uuid.UUID `json:"id" db:"id"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
	Target    string    `json:"target" db:"target"`
	Comment   string    `json:"comment" db:"comment"`
	Url       string    `json:"url" db:"url"`
}

// String is not required by pop and may be deleted
func (c Comment) String() string {
	jc, _ := json.Marshal(c)
	return string(jc)
}

// Comments is not required by pop and may be deleted
type Comments []Comment

// String is not required by pop and may be deleted
func (c Comments) String() string {
	jc, _ := json.Marshal(c)
	return string(jc)
}

// Validate gets run every time you call a "pop.Validate*" (pop.ValidateAndSave, pop.ValidateAndCreate, pop.ValidateAndUpdate) method.
// This method is not required and may be deleted.
func (c *Comment) Validate(tx *pop.Connection) (*validate.Errors, error) {

	fmt.Println("validating")
	fmt.Println(c.Target + c.Comment + c.Url)

	return validate.Validate(
		&validators.StringIsPresent{Field: c.Target, Name: "Target"},
		&validators.StringIsPresent{Field: c.Comment, Name: "Comment"},
		&validators.StringIsPresent{Field: c.Url, Name: "Url"},
	), nil
}

// ValidateCreate gets run every time you call "pop.ValidateAndCreate" method.
// This method is not required and may be deleted.
func (c *Comment) ValidateCreate(tx *pop.Connection) (*validate.Errors, error) {
	return validate.NewErrors(), nil
}

// ValidateUpdate gets run every time you call "pop.ValidateAndUpdate" method.
// This method is not required and may be deleted.
func (c *Comment) ValidateUpdate(tx *pop.Connection) (*validate.Errors, error) {
	return validate.NewErrors(), nil
}
