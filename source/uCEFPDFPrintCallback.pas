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

unit uCEFPDFPrintCallback;

{$IFNDEF CPUX64}
  {$ALIGN ON}
  {$MINENUMSIZE 4}
{$ENDIF}

{$I cef.inc}

interface

uses
  uCEFBaseRefCounted, uCEFInterfaces, uCEFTypes;

type
  TCefPdfPrintCallbackOwn = class(TCefBaseRefCountedOwn, ICefPdfPrintCallback)
    protected
      procedure OnPdfPrintFinished(const path: ustring; ok: Boolean); virtual; abstract;

    public
      constructor Create; virtual;
  end;

  TCefFastPdfPrintCallback = class(TCefPdfPrintCallbackOwn)
    protected
      FProc: TOnPdfPrintFinishedProc;

      procedure OnPdfPrintFinished(const path: ustring; ok: Boolean); override;

    public
      constructor Create(const proc: TOnPdfPrintFinishedProc); reintroduce;
  end;

  TCefPDFPrintCallBack = class(TCefPdfPrintCallbackOwn)
    protected
      FChromiumBrowser : TObject;

      procedure OnPdfPrintFinished(const path: ustring; aResultOK : Boolean); override;

    public
      constructor Create(const aChromiumBrowser : TObject); reintroduce;
  end;

implementation

uses
  uCEFMiscFunctions, uCEFLibFunctions, uCEFChromium;

procedure cef_pdf_print_callback_on_pdf_print_finished(self: PCefPdfPrintCallback; const path: PCefString; ok: Integer); stdcall;
begin
  with TCefPdfPrintCallbackOwn(CefGetObject(self)) do OnPdfPrintFinished(CefString(path), ok <> 0);
end;

constructor TCefPdfPrintCallbackOwn.Create;
begin
  CreateData(SizeOf(TCefPdfPrintCallback), False);

  with PCefPdfPrintCallback(FData)^ do on_pdf_print_finished := cef_pdf_print_callback_on_pdf_print_finished;
end;

// TCefFastPdfPrintCallback

constructor TCefFastPdfPrintCallback.Create(const proc: TOnPdfPrintFinishedProc);
begin
  FProc := proc;
  inherited Create;
end;

procedure TCefFastPdfPrintCallback.OnPdfPrintFinished(const path: ustring; ok: Boolean);
begin
  FProc(path, ok);
end;

// TCefPDFPrintCallBack

constructor TCefPDFPrintCallBack.Create(const aChromiumBrowser : TObject);
begin
  inherited Create;

  FChromiumBrowser := aChromiumBrowser;
end;

procedure TCefPDFPrintCallBack.OnPdfPrintFinished(const path: ustring; aResultOK : Boolean);
begin
  if (FChromiumBrowser <> nil) and (FChromiumBrowser is TChromium) then
    TChromium(FChromiumBrowser).Internal_PdfPrintFinished(aResultOK);
end;

end.
