import Vapor

//Example

//token=gIkuvaNzQIHg97ATvDxqgjtO
//team_id=T0001
//team_domain=example
//enterprise_id=E0001
//enterprise_name=Globular%20Construct%20Inc
//channel_id=C2147483705
//channel_name=test
//user_id=U2147483697
//user_name=Steve
//command=/weather
//text=94070
//response_url=https://hooks.slack.com/commands/1234/5678
//trigger_id=13345224609.738474920.8088930838d88f008e0

struct SlashCommand: Content {
    static let defaultMediaType: MediaType = .urlEncodedForm

    let token: String
    let teamId: String
    let teamDomain: String
    let enterpriseId: String?
    let enterpriseName: String?
    let channelId: String
    let channelName: String
    let userId: String
    let userName: String
    let command: String
    let text: String
    let responseURL: String
    let triggerId: String

    enum CodingKeys: String, CodingKey {
        case token
        case teamId = "team_id"
        case teamDomain = "team_domain"
        case enterpriseId = "enterprise_id"
        case enterpriseName = "enterprise_name"
        case channelId = "channel_id"
        case channelName = "channel_name"
        case userId = "user_id"
        case userName = "user_name"
        case command
        case text
        case responseURL = "response_url"
        case triggerId = "trigger_id"
    }
}
