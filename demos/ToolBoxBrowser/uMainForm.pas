// ************************************************************************
// ***************************** CEF4Delphi *******************************
// ************************************************************************
//
// CEF4Delphi is based on DCEF3 which uses CEF3 to embed a chromium-based
// browser in Delphi applications.
//
// The original license of DCEF3 still applies to CEF4Delphi.
//
// For more information about CEF4Delphi visit :
//         https://www.briskbard.com/index.php?lang=en&pageid=cef
//
//        Copyright � 2017 Salvador D�az Fau. All rights reserved.
//
// ************************************************************************
// ************ vvvv Original license and comments below vvvv *************
// ************************************************************************
(*
 *                       Delphi Chromium Embedded 3
 *
 * Usage allowed under the restrictions of the Lesser GNU General Public License
 * or alternatively the restrictions of the Mozilla Public License 1.1
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 *
 * Unit owner : Henri Gourvest <hgourvest@gmail.com>
 * Web site   : http://www.progdigy.com
 * Repository : http://code.google.com/p/delphichromiumembedded/
 * Group      : http://groups.google.com/group/delphichromiumembedded
 *
 * Embarcadero Technologies, Inc is not permitted to use or redistribute
 * this source code without explicit permission.
 *
 *)

unit uMainForm;

{$I cef.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;
  {$ELSE}
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls;
  {$ENDIF}

const
  CEFBROWSER_CREATED          = WM_APP + $100;
  CEFBROWSER_CHILDDESTROYED   = WM_APP + $101;

type
  TMainForm = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    // Variables to control when can we destroy the form safely
    FCanClose : boolean;  // Set to True when the final timer is triggered
    FClosing  : boolean;  // Set to True in the CloseQuery event.

    procedure CreateToolboxChild(const ChildCaption, URL: string);
    procedure CloseAllChildForms;
    function  GetChildClosing : boolean;
    function  GetChildFormCount : integer;

  protected
    procedure ChildDestroyedMsg(var aMessage : TMessage); message CEFBROWSER_CHILDDESTROYED;

  public
    function CloseQuery: Boolean; override;

    property ChildClosing : boolean read GetChildClosing;
    property ChildFormCount : integer read GetChildFormCount;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  uChildForm;

// Destruction steps
// =================
// 1. Destroy all child forms
// 2. Enable a Timer and wait for 1 second
// 3. Close and destroy the main form

procedure TMainForm.CreateToolboxChild(const ChildCaption, URL: string);
var
  TempChild : TChildForm;
begin
  TempChild          := TChildForm.Create(self);
  TempChild.Caption  := ChildCaption;
  TempChild.Homepage := URL;
  TempChild.Show;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCanClose := False;
  FClosing  := False;
end;

procedure TMainForm.CloseAllChildForms;
var
  i : integer;
  TempComponent : TComponent;
begin
  i := pred(ComponentCount);

  while (i >= 0) do
    begin
      TempComponent := Components[i];

      if (TempComponent <> nil) and
         (TempComponent is TChildForm) and
         not(TChildForm(Components[i]).Closing) then
        PostMessage(TChildForm(Components[i]).Handle, WM_CLOSE, 0, 0);

      dec(i);
    end;
end;

function TMainForm.GetChildClosing : boolean;
var
  i : integer;
  TempComponent : TComponent;
begin
  Result := false;
  i      := pred(ComponentCount);

  while (i >= 0) do
    begin
      TempComponent := Components[i];

      if (TempComponent <> nil) and
         (TempComponent is TChildForm) then
        begin
          if TChildForm(Components[i]).Closing then
            begin
              Result := True;
              exit;
            end
           else
            dec(i);
        end
       else
        dec(i);
    end;
end;

function TMainForm.GetChildFormCount : integer;
var
  i : integer;
  TempComponent : TComponent;
begin
  Result := 0;
  i      := pred(ComponentCount);

  while (i >= 0) do
    begin
      TempComponent := Components[i];

      if (TempComponent <> nil) and
         (TempComponent is TChildForm) then
        inc(Result);

      dec(i);
    end;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;

  if not(FCanClose) then
    begin
      FCanClose := True;
      PostMessage(self.Handle, WM_CLOSE, 0, 0);
    end;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  CreateToolboxChild('Browser', Edit1.Text);
end;

procedure TMainForm.ChildDestroyedMsg(var aMessage : TMessage);
begin
  // If there are no more child forms we can destroy the main form
  if FClosing and (ChildFormCount = 0) then
    begin
      ShowWindow(Handle, SW_HIDE);
      Timer1.Enabled := True;
    end;
end;

function TMainForm.CloseQuery: Boolean;
begin
  if FClosing or ChildClosing then
    Result := FCanClose
   else
    begin
      FClosing := True;

      if (ChildFormCount = 0) then
        Result := True
       else
        begin
          Result          := False;
          Edit1.Enabled   := False;
          Button1.Enabled := False;

          CloseAllChildForms;
        end;
    end;
end;

end.