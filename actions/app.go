package actions

import (
	"fmt"

	"github.com/gobuffalo/buffalo"
	"github.com/gobuffalo/buffalo/middleware"
	"github.com/gobuffalo/buffalo/middleware/ssl"
	"github.com/gobuffalo/envy"
	"github.com/markbates/pop"
	"github.com/pkg/errors"
	"github.com/unrolled/secure"

	"github.com/gobuffalo/x/sessions"
	"github.com/narrative/backend/models"
)

// ENV is used to help switch settings based on where the
// application is being run. Default is "development".
var ENV = envy.Get("GO_ENV", "development")
var app *buffalo.App

// App is where all routes and middleware for buffalo
// should be defined. This is the nerve center of your
// application.
func App() *buffalo.App {
	if app == nil {
		app = buffalo.New(buffalo.Options{
			Env:          ENV,
			SessionStore: sessions.Null{},
			SessionName:  "_backend_session",
		})
		// Automatically redirect to SSL
		app.Use(ssl.ForceSSL(secure.Options{
			SSLRedirect:     ENV == "production",
			SSLProxyHeaders: map[string]string{"X-Forwarded-Proto": "https"},
		}))

		// Set the request content type to JSON
		app.Use(middleware.SetContentType("application/json"))

		app.Use(addCORS)

		if ENV == "development" {
			app.Use(middleware.ParameterLogger)
		}

		// Wraps each request in a transaction.
		//  c.Value("tx").(*pop.PopTransaction)
		// Remove to disable this.
		app.Use(middleware.PopTransaction(models.DB))

		app.GET("/", HomeHandler)

		app.Resource("/comments", CommentsResource{})
		app.OPTIONS("/comments", func(c buffalo.Context) error {
			return c.Render(200, r.String("hello"))
		})

		app.GET("/search", func(c buffalo.Context) error {

			tx, ok := c.Value("tx").(*pop.Connection)
			if !ok {
				return errors.WithStack(errors.New("no transaction found"))
			}

			search := &models.Search{}
			c.Bind(&search)

			comments := &models.Comments{}
			fmt.Println(search.Url)
			q := tx.Where(fmt.Sprintf("url='%s'", search.Url))

			// Retrieve all Comments from the DB
			if err := q.All(comments); err != nil {
				return errors.WithStack(err)
			}

			return c.Render(200, r.JSON(comments))

		})

		app.Resource("/comments", CommentsResource{})
	}

	return app
}

func addCORS(next buffalo.Handler) buffalo.Handler {
	return func(c buffalo.Context) error {
		c.Response().Header().Add("Access-Control-Allow-Origin", "*")
		c.Response().Header().Add("Access-Control-Allow-Headers", "Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With, Cache-Control")
		fmt.Println("adding headers")
		err := next(c)
		return err
	}
}
