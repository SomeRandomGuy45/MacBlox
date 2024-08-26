#include "window.h"
#include "frame.h"

wxIMPLEMENT_APP(App);

bool App::OnInit() {
    long frameStyle = wxDEFAULT_FRAME_STYLE & ~(wxRESIZE_BORDER | wxMAXIMIZE_BOX);
    MainFrame* frame = new MainFrame("Macblox Helper", frameStyle, wxSize(600, 400));
    frame->Center();
    if (!frame->Show())
    {
        CreateNotification("Error", "Unable to start up app", -1);
        return false;
    }
    return true;
}