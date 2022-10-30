// DebugDlg.cpp : implementation file
//

#include "stdafx.h"
#include "U2S_GUI.h"
#include "DebugDlg.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// DebugDlg dialog


DebugDlg::DebugDlg(CWnd* pParent /*=NULL*/)
	: CDialog(DebugDlg::IDD, pParent)
{
	//{{AFX_DATA_INIT(DebugDlg)
		// NOTE: the ClassWizard will add member initialization here
	//}}AFX_DATA_INIT
}


void DebugDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(DebugDlg)
		// NOTE: the ClassWizard will add DDX and DDV calls here
	//}}AFX_DATA_MAP
}


BEGIN_MESSAGE_MAP(DebugDlg, CDialog)
	//{{AFX_MSG_MAP(DebugDlg)
	ON_WM_PAINT()
	ON_WM_MOUSEMOVE()
	ON_WM_LBUTTONUP()
	ON_WM_TIMER()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// DebugDlg message handlers

#include "U2S.h"

extern U2S u2s;

const int xo=80;
const int yo=20;
const int xys = 20;


BOOL DebugDlg::OnInitDialog() 
{
	CDialog::OnInitDialog();

	X = Y = 0;
	SetTimer(1,200,NULL);
	
	return TRUE;  // return TRUE unless you set the focus to a control
	              // EXCEPTION: OCX Property Pages should return FALSE
}

//-------------------------------------------------------------------

const char *ports[] = {
"PINB","DDRB","PORTB",
"PINC","DDRC","PORTC",
"PIND","DDRD","PORTD",
};

const char enable[] = {
0xFF,0xFF,0xFF,
0xF0,0xF0,0xF0,
0xFF,0xFF,0xFF,
};

bool BitEnabled(int bit, int y)
{
	return ((enable[y] >> bit) & 1) == 1;
}

char state[] = {
0x00,0x00,0x00,
0x00,0x00,0x00,
0x00,0x00,0x00,
};

bool GetBit(int bit, int y)
{
	return ((state[y] >> bit) & 1) == 1;
}

void SetByte(int bit, int y)
{
	u2s.WriteByte(0x23+y,1<<bit);
}

void SetBit(int bit, int y)
{
	state[y] |= 1 << bit;
	u2s.WriteBit(0x23+y,0xFF,1<<bit);
}

void ClrBit(int bit, int y)
{
	state[y] &= ~(1 << bit);
	u2s.WriteBit(0x23+y,~(1 << bit),0x00);
}

//-------------------------------------------------------------------

void DebugDlg::OnTimer(UINT nIDEvent) 
{
	u2s.ReadBytes(0x23,9,(u8*)state);
	InvalidateRect(NULL,FALSE);
	
	CDialog::OnTimer(nIDEvent);
}

//-------------------------------------------------------------------

void DebugDlg::OnPaint() 
{
	CPaintDC dc(this); // device context for painting
	
	int x,y;

	for(x=0; x<9; x++) {
		dc.MoveTo(xo + xys * x, yo);
		dc.LineTo(xo + xys * x, yo + (xys * 9));
	}
	
	for(y=0; y<10; y++) {
		dc.MoveTo(xo,             yo + xys * y);
		dc.LineTo(xo + (xys * 8), yo + xys * y);
	}

	for(y=0; y<9; y++)
	for(x=0; x<8; x++) {
		if(!BitEnabled(7-x,y)) {
			dc.FillSolidRect(xo + xys * x + 3, yo + xys * y + 3,
				xys-5,xys-5,RGB(140,140,140));
		}
		if(GetBit(7-x,y)) {
			dc.FillSolidRect(xo + xys * x + 6, yo + xys * y + 6,
				xys-11,xys-11,RGB(0,200,0));
		}else{
			dc.FillSolidRect(xo + xys * x + 6, yo + xys * y + 6,
				xys-11,xys-11,RGB(240,0,0));
		}
	}

	RECT r;
	dc.SetBkColor(GetSysColor(COLOR_3DFACE));
	for(y=0; y<9; y++) {
		r.top = yo + (xys * y) + 4;
		r.bottom = r.top + 20;
		r.left = xo - 60;
		r.right = xo;
		dc.DrawText(ports[y],strlen(ports[y]),&r,0);
	}

	DRect(&dc,0,X,Y);

	// Do not call CDialog::OnPaint() for painting messages
}

//-------------------------------------------------------------------

void DebugDlg::OnLButtonUp(UINT nFlags, CPoint point) 
{
	int x = (point.x - xo) / xys;
	int y = (point.y - yo) / xys;

	if(x >= 0 && x <= 7 && y >= 0 && y <= 8) {
		if(BitEnabled(7-x,y)) {
			if((y%3) == 0) {
				SetByte(7-x,y); //PINx
			}else
			if(GetBit(7-x,y)) {
				ClrBit(7-x,y);
			}else{
				SetBit(7-x,y);
			}
			InvalidateRect(NULL,FALSE);
		}
	}
	
	CDialog::OnLButtonUp(nFlags, point);
}

//-------------------------------------------------------------------

void DebugDlg::DRect(CDC *dc, COLORREF c, int x, int y)
{
	int a = xo + x * xys;
	int b = yo + y * xys;
	CRect r;
	CBrush h(c);
	r.SetRect(a,b,a+xys+1,b+xys+1);
	r.DeflateRect(1,1);
	dc->FrameRect(&r,&h);

}

void DebugDlg::Highlight(int x, int y)
{
	if(x == X && y == Y) {
		return;
	}

	CClientDC dc(this);

	DRect(&dc,0,x,y);
	if(X >= 0 && Y >= 0) {
		DRect(&dc,GetSysColor(COLOR_3DFACE),X,Y);
	}

	X = x;
	Y = y;
}

void DebugDlg::OnMouseMove(UINT nFlags, CPoint point) 
{
	int x = (point.x - xo) / xys;
	int y = (point.y - yo) / xys;

	if(x >= 0 && x <= 7 && y >= 0 && y <= 8) {
		Highlight(x,y);
	}
		
	CDialog::OnMouseMove(nFlags, point);
}

//-------------------------------------------------------------------


