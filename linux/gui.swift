import VertexGUI
import Foundation

let dateFormatter: DateFormatter = { 
    let result = DateFormatter()
    result.dateStyle = .short
    result.locale = Locale.current
    return result
}()

public class MainView: ComposedWidget {
  @State
  private var counter = 0

  @State 
  private var date = Date()

  @Compose override public var content: ComposedContent {
    Container().with(classes: ["vstack"]).withContent { [unowned self] in
        Container().with(classes: ["container"]).withContent { [unowned self] in
            Button().onClick {
                self.date = self.date.dateByAddingDays(-1)
            }.withContent {
                Text("Previous")
            }
            Text(ImmutableBinding($date.immutable, get: { dateFormatter.string(from: $0) } ))
            Button().onClick {
                self.date = self.date.nextDay
            }.withContent {
                Text("Next")
            }
        }
        Container().with(classes: ["container"]).withContent { [unowned self] in
            Text("next line")
        }
        Container().with(classes: ["container"]).withContent { [unowned self] in
            Text("another one")
        }
    }
  }

  // this is basically copied from demo. Hopefully I will find a way to look native
  override public var style: Style {
    let primaryColor = Color(77, 154, 255, 255)

    return Style("&") {
      (\.$background, Color(180, 180, 180, 255))
    } nested: {

      Style(".container", Container.self) {
        (\.$alignContent, .center)
        (\.$justifyContent, .center)
      }

      Style(".vstack", Container.self) {
        (\.$direction, .column)
        (\.$alignContent, .stretch)
        (\.$justifyContent, .start)
      }

      Style(".hstack", Container.self) {
        (\.$direction, .row)
        (\.$alignContent, .stretch)
        (\.$justifyContent, .center)
      }

      Style("Button") {
        (\.$padding, Insets(all: 16))
        (\.$background, primaryColor)
        (\.$foreground, .black)
        (\.$fontWeight, .bold)
      } nested: {

        Style("&:hover") {
          (\.$background, primaryColor.darkened(20))
        }

        Style("&:active") {
          (\.$background, primaryColor.darkened(40))
        }
      }
    }
  }
}
