--TK:449ca24f-8c0d-4a7b-ba99-e339efdf479a
port module Main exposing (..)

import Html exposing (Html, a, button, code, div, h1, h4, h5, i, img, input, label, option, p, pre, select, span, text, table, tbody, tr, td)
import Html.Attributes exposing (attribute, class, disabled, for, href, id, name, placeholder, property, selected, type_, value, width)
import Html.Events exposing (onInput, onClick)
import Json.Encode as Json
import Maybe.Extra as Maybe exposing ((?))
import Regex as Regex exposing (regex)


type alias Model =
    { activeServices : List Service
    , highlightedOutput : String
    }


toValue : Model -> Json.Value
toValue model =
    Json.object
        [ ( "version", Json.string "3" )
        , ( "services"
          , Json.object
                (List.map
                    (\service ->
                        ( serviceNameToString service.name
                        , Json.object
                            [ ( "restart", Json.string "always" )
                            , ( "image", Json.string (service.image.name ++ ":" ++ service.image.version) )
                            , ( "ports", Json.list (List.map (portMapToString >> Json.string) service.ports) )
                            , ( "environment", Json.object (List.map environmentVariableToStringValue service.environment) )
                            ]
                        )
                    )
                    model.activeServices
                )
          )
        ]


type HostVolume
    = Path String
    | Named String


type alias Volume =
    { host : HostVolume
    , container : String
    , readonly : Bool
    }


type alias EnvVar =
    { key : String
    , value : String
    }


type EnvVarComponent
    = Key
    | Value


type alias PortMap =
    { host : Int
    , container : Int
    }


type alias Image =
    { name : String
    , version : String
    }


type alias Service =
    { name : String
    , description : String
    , image : Image
    , environment : List EnvVar
    , ports : List PortMap
    , volumes : List Volume
    , command : Maybe String
    , required : Bool
    }


defaultService : String -> Image -> Service
defaultService name image =
    { name = name
    , description = "No description available"
    , image = image
    , environment = []
    , ports = []
    , volumes = []
    , command = Nothing
    , required = False
    }


defaultImage : Image
defaultImage =
    Image "" ""


withPorts : List PortMap -> Service -> Service
withPorts ports service =
    { service | ports = ports }


withEnv : List EnvVar -> Service -> Service
withEnv environment service =
    { service | environment = environment }


withVolumes : List Volume -> Service -> Service
withVolumes volumes service =
    { service | volumes = volumes }


withCommand : String -> Service -> Service
withCommand command service =
    { service | command = Just command }


makeRequired : Service -> Service
makeRequired service =
    { service | required = True }


services : List Service
services =
    [ defaultService "NGINX" (Image "jwilder/nginx-proxy" "latest")
        |> withPorts [ PortMap 80 80, PortMap 443 443 ]
        |> makeRequired
    , defaultService "Let's Encrypt" (Image "jrcs/letsencrypt-nginx-proxy-companion" "latest")
        |> makeRequired
    , defaultService "MySQL" (Image "mysql" "5.7")
    , defaultService "PostgreSQL" (Image "postgres" "10.1")
    , defaultService "Gogs" (Image "gogs/gogs" "latest")
    , defaultService "Drone Server" (Image "drone/drone" "latest")
    , defaultService "Drone Agent" (Image "drone/agent" "latest")
    , defaultService "Redis" (Image "redis" "latest")
    , defaultService "Wordpress" (Image "wordpress" "latest")
    , defaultService "custom" defaultImage
    ]


requiredServices : List Service
requiredServices =
    List.filter (\s -> s.required == True) services


optionalServices : List Service
optionalServices =
    List.filter (\s -> s.required == False) services


environmentVariableToStringValue : EnvVar -> ( String, Json.Value )
environmentVariableToStringValue envvar =
    ( envvar.key, Json.string envvar.value )


serviceNameToString : String -> String
serviceNameToString serviceName =
    serviceName
        |> String.toLower
        |> (Regex.replace Regex.All (regex "[^a-zA-Z0-9-]+") (\_ -> ""))


portMapToString : PortMap -> String
portMapToString portMap =
    toString portMap.host ++ ":" ++ toString portMap.container


init : ( Model, Cmd Msg )
init =
    let
        initialModel =
            { activeServices = requiredServices
            , highlightedOutput = ""
            }
    in
        ( initialModel
        , highlight initialModel
        )



---- UPDATE ----


type Msg
    = NoOp
    | OnAddService String
    | OnClickRemoveService Int
    | OnClickAddEnvVar Int
    | OnClickRemoveEnvVar Int Int
    | OnChangeEnvVar EnvVarComponent Int Int String
    | OutputHighlighted String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        OutputHighlighted highlightedOutput ->
            ( { model | highlightedOutput = highlightedOutput }
            , Cmd.none
            )

        OnAddService service ->
            let
                selectedService =
                    optionalServices
                        |> List.filter (\s -> s.name == service)
                        |> List.head

                updatedModel =
                    { model
                        | activeServices =
                            model.activeServices ++ Maybe.unwrap [] List.singleton selectedService
                    }
            in
                ( updatedModel
                , highlight updatedModel
                )

        OnClickRemoveService index ->
            let
                updatedModel =
                    { model
                        | activeServices =
                            listRemoveAt index model.activeServices
                    }
            in
                ( updatedModel
                , highlight updatedModel
                )

        OnClickAddEnvVar serviceIndex ->
            let
                updatedModel =
                    { model
                        | activeServices =
                            listUpdateAt model.activeServices serviceIndex <|
                                \service ->
                                    { service
                                        | environment = EnvVar "" "" :: service.environment
                                    }
                    }
            in
                ( updatedModel
                , highlight updatedModel
                )

        OnChangeEnvVar component serviceIndex envVarIndex newValue ->
            let
                updatedModel =
                    { model
                        | activeServices =
                            listUpdateAt model.activeServices serviceIndex <|
                                \service ->
                                    { service
                                        | environment =
                                            listUpdateAt service.environment envVarIndex <|
                                                \x ->
                                                    case component of
                                                        Key ->
                                                            { x | key = newValue }

                                                        Value ->
                                                            { x | value = newValue }
                                    }
                    }
            in
                ( updatedModel
                , highlight updatedModel
                )

        OnClickRemoveEnvVar serviceIndex envVarIndex ->
            ( { model
                | activeServices =
                    listUpdateAt model.activeServices serviceIndex <|
                        \service ->
                            { service
                                | environment =
                                    listRemoveAt envVarIndex service.environment
                            }
              }
            , Cmd.none
            )



---- VIEW ----


servicesView : List Service -> Html Msg
servicesView =
    List.indexedMap serviceCard >> div []


serviceCard : Int -> Service -> Html Msg
serviceCard index service =
    when (not service.required) <|
        div [ class "card mb-3" ]
            [ div [ class "card-header" ]
                [ text service.name
                , button
                    [ class "float-right close"
                    , onClick (OnClickRemoveService index)
                    ]
                    [ text "×" ]
                ]
            , div [ class "card-block" ]
                [ div [ class "card-body" ]
                    [ p [ class "card-text" ]
                        [ text service.description ]
                    , div [ class "row" ]
                        [ div [ class "col-md-4" ]
                            [ p [ class "card-text text-center" ]
                                [ text "Environment Variables" ]
                            ]
                        , div [ class "col-md-8" ]
                            [ button
                                [ class "btn btn-block btn-primary"
                                , onClick (OnClickAddEnvVar index)
                                ]
                                [ text "Add" ]
                            , table [ class "table" ]
                                [ tbody []
                                    [ tr []
                                        (List.indexedMap (environmentVariablePair index) service.environment)
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]


environmentVariablePair : Int -> Int -> EnvVar -> Html Msg
environmentVariablePair serviceIndex index var =
    tr []
        [ td []
            [ input
                [ class "form-control"
                , value var.key
                , onInput (OnChangeEnvVar Key serviceIndex index)
                ]
                []
            ]
        , td []
            [ input
                [ class "form-control"
                , value var.value
                , onInput (OnChangeEnvVar Value serviceIndex index)
                ]
                []
            ]
        , td []
            [ button
                [ class "btn btn-danger"
                , onClick (OnClickRemoveEnvVar serviceIndex index)
                ]
                [ i [ class "fas fa-trash" ] [] ]
            ]
        ]


view : Model -> Html Msg
view model =
    div [ class "container-fluid" ]
        [ h1 [ class "display-4" ] [ text "loading dock" ]
        , div [ class "row" ]
            [ div [ class "col" ]
                [ div [ class "form-group row" ]
                    [ label [ class "col-4 col-form-label", for "root_domain" ]
                        [ text "Root Domain" ]
                    , div [ class "col-8" ]
                        [ input [ class "form-control here", id "root_domain", name "root_domain", placeholder "example.com", attribute "required" "required", type_ "text" ]
                            []
                        ]
                    ]
                , div [ class "form-group row" ]
                    [ label [ class "col-4 col-form-label", for "email" ]
                        [ text "Email" ]
                    , div [ class "col-8" ]
                        [ input [ attribute "aria-describedby" "emailHelpBlock", class "form-control here", id "email", name "email", placeholder "admin@example.com", type_ "text" ]
                            []
                        , span [ class "form-text text-muted", id "emailHelpBlock" ]
                            [ text "This email address is used to acquire SSL certificates from Let's Encrypt." ]
                        ]
                    ]
                , div [ class "form-group row" ]
                    [ label [ class "col-4 col-form-label", for "service" ]
                        [ text "Add Service" ]
                    , div [ class "col-8" ]
                        [ select [ class "custom-select", id "service", name "service", value "default", onInput OnAddService ]
                            (option [ value "default", disabled True, selected True ] [ text "Select a service to add" ]
                                :: (optionalServices
                                        |> List.map (\x -> option [ value x.name ] [ text x.name ])
                                   )
                            )
                        ]
                    ]
                , servicesView model.activeServices
                ]
            , div [ class "col" ]
                [ div [ class "card" ]
                    [ div [ class "card-body" ]
                        [ h5 [ class "card-title" ]
                            [ text "docker-compose.yml" ]
                        , pre [ class "card-text" ]
                            [ code
                                [ class "json hljs"
                                , property "innerHTML" (Json.string model.highlightedOutput)
                                ]
                                []
                            ]
                        ]
                    ]
                ]
            ]
        ]



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always (highlighterOutputPort OutputHighlighted)
        }



---- PORTS ----


highlight : Model -> Cmd msg
highlight =
    toValue >> Json.encode 4 >> highlightPort


port highlightPort : String -> Cmd msg


port highlighterOutputPort : (String -> msg) -> Sub msg



---- UTILITIES ----


when : Bool -> Html Msg -> Html Msg
when p html =
    if p then
        html
    else
        text ""


listRemoveAt : Int -> List a -> List a
listRemoveAt index xs =
    (List.take index xs) ++ (List.drop (index + 1) xs)


listUpdateAt : List a -> Int -> (a -> a) -> List a
listUpdateAt xs index f =
    List.indexedMap
        (\i x ->
            if i == index then
                f x
            else
                x
        )
        xs


listSetAt : List a -> Int -> a -> List a
listSetAt xs index a =
    listUpdateAt xs index (always a)

