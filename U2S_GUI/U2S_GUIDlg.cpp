// U2S_GUIDlg.cpp : implementation file
//

#include "stdafx.h"
#include "U2S_GUI.h"
#include "U2S_GUIDlg.h"
#include "U2S.h"
#include "DebugDlg.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CAboutDlg dialog used for App About

class CAboutDlg : public CDialog
{
public:
	CAboutDlg();

// Dialog Data
	//{{AFX_DATA(CAboutDlg)
	enum { IDD = IDD_ABOUTBOX };
	//}}AFX_DATA

	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CAboutDlg)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:
	//{{AFX_MSG(CAboutDlg)
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

CAboutDlg::CAboutDlg() : CDialog(CAboutDlg::IDD)
{
	//{{AFX_DATA_INIT(CAboutDlg)
	//}}AFX_DATA_INIT
}

void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CAboutDlg)
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CAboutDlg, CDialog)
	//{{AFX_MSG_MAP(CAboutDlg)
		// No message handlers
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CU2S_GUIDlg dialog

CU2S_GUIDlg::CU2S_GUIDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CU2S_GUIDlg::IDD, pParent)
{
	//{{AFX_DATA_INIT(CU2S_GUIDlg)
	m_Partid = _T("");
	m_Serial = _T("");
	m_Version = 0;
	m_AppSize = _T("");
	//}}AFX_DATA_INIT
	// Note that LoadIcon does not require a subsequent DestroyIcon in Win32
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
}

void CU2S_GUIDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CU2S_GUIDlg)
	DDX_Control(pDX, IDC_COMBO1, m_ComPort);
	DDX_Text(pDX, IDC_EDIT9, m_Partid);
	DDX_Text(pDX, IDC_EDIT10, m_Serial);
	DDX_Text(pDX, IDC_EDIT11, m_Version);
	DDX_Text(pDX, IDC_EDIT12, m_AppSize);
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CU2S_GUIDlg, CDialog)
	//{{AFX_MSG_MAP(CU2S_GUIDlg)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	ON_BN_CLICKED(IDC_BUTTON1, OnSetToBL)
	ON_BN_CLICKED(IDC_BUTTON4, OnSetToApp)
	ON_BN_CLICKED(IDC_BUTTON6, OnSetToDebug)
	ON_BN_CLICKED(IDC_BUTTON7, OnUpdateInfo)
	ON_CBN_SELCHANGE(IDC_COMBO1, OnSelchangeCombo1)
	ON_BN_CLICKED(IDC_BUTTON8, OnSetToJTAG)
	ON_BN_CLICKED(IDC_BUTTON3, OnModUnlock)
	ON_BN_CLICKED(IDC_BUTTON2, OnSetToSTK500)
	ON_BN_CLICKED(IDC_BUTTON9, OnSetToUART)
	ON_BN_CLICKED(IDC_BUTTON10, OnSetToDW)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CU2S_GUIDlg message handlers


BOOL CU2S_GUIDlg::OnInitDialog()
{
	CDialog::OnInitDialog();

	// Add "About..." menu item to system menu.

	// IDM_ABOUTBOX must be in the system command range.
	ASSERT((IDM_ABOUTBOX & 0xFFF0) == IDM_ABOUTBOX);
	ASSERT(IDM_ABOUTBOX < 0xF000);

	CMenu* pSysMenu = GetSystemMenu(FALSE);
	if (pSysMenu != NULL)
	{
		CString strAboutMenu;
		strAboutMenu.LoadString(IDS_ABOUTBOX);
		if (!strAboutMenu.IsEmpty())
		{
			pSysMenu->AppendMenu(MF_SEPARATOR);
			pSysMenu->AppendMenu(MF_STRING, IDM_ABOUTBOX, strAboutMenu);
		}
	}

	// Set the icon for this dialog.  The framework does this automatically
	//  when the application's main window is not a dialog
	SetIcon(m_hIcon, TRUE);			// Set big icon
	SetIcon(m_hIcon, FALSE);		// Set small icon
	
	// TODO: Add extra initialization here
	m_ComPort.SetCurSel(2); //COM3
	OnUpdateInfo();

	return TRUE;  // return TRUE  unless you set the focus to a control
}

void CU2S_GUIDlg::OnSysCommand(UINT nID, LPARAM lParam)
{
	if ((nID & 0xFFF0) == IDM_ABOUTBOX)
	{
		CAboutDlg dlgAbout;
		dlgAbout.DoModal();
	}
	else
	{
		CDialog::OnSysCommand(nID, lParam);
	}
}

// If you add a minimize button to your dialog, you will need the code below
//  to draw the icon.  For MFC applications using the document/view model,
//  this is automatically done for you by the framework.

void CU2S_GUIDlg::OnPaint() 
{
	if (IsIconic())
	{
		CPaintDC dc(this); // device context for painting

		SendMessage(WM_ICONERASEBKGND, (WPARAM) dc.GetSafeHdc(), 0);

		// Center icon in client rectangle
		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		// Draw the icon
		dc.DrawIcon(x, y, m_hIcon);
	}
	else
	{
		CDialog::OnPaint();
	}
}

// The system calls this to obtain the cursor to display while the user drags
//  the minimized window.
HCURSOR CU2S_GUIDlg::OnQueryDragIcon()
{
	return (HCURSOR) m_hIcon;
}


//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

U2S u2s;

bool CU2S_GUIDlg::Connect(BYTE m)
{
	CString cs; //CComboBox should have had a member called GetText... grrrr
	int i = m_ComPort.GetCurSel();
	if(i == CB_ERR) {
		m_ComPort.GetWindowText(cs);
	}else{
		m_ComPort.GetLBText(m_ComPort.GetCurSel(),cs);
	}


	if(!u2s.Connect(cs,m)) {
		m_Serial = "Failed to connect";
		UpdateData(FALSE);
		return 0;
	}

	Sleep(500);

	m &= 0x8F;
	if(m == 0x81 || m == 0x82)
	if(!u2s.SignOn()) {
		m_Serial = "Failed to Sign On";
		UpdateData(FALSE);
		return 0;
	}

	return 1;
}

void CU2S_GUIDlg::Disconnect()
{
	u2s.Disconnect();
}

//-----------------------------------------------------------------------------

const char *tohex = "0123456789ABCDEF";

void CU2S_GUIDlg::OnUpdateInfo() 
{
	int i;
	char buf[10];

	if(!Connect(0x81)) {
		return;
	}

//	u2s.SelectMode(0x81);
//	u2s.GetMode(); //wait for Mode to change...


	m_Partid = "";
	for(i=0; i<3; i++) {
		u8 u = u2s.ReadSig(i);
		m_Partid += tohex[(u>>4)&0xF];
		m_Partid += tohex[(u>>0)&0xF];
		m_Partid += ' ';
	}


	u8 bf[10];
	u2s.GetSerial(bf);
	m_Serial = "";
	for(i=0; i<10; i++) {
		m_Serial += tohex[(bf[i]>>4)&0xF];
		m_Serial += tohex[(bf[i]>>0)&0xF];
		m_Serial += ' ';
	}


	m_Version = u2s.GetVersion();
	

	u16 u = u2s.GetAppSize();
	m_AppSize = "0x";
	itoa(u,buf,16);
	m_AppSize += buf;
	m_AppSize += " - ";
	itoa(u,buf,10);
	m_AppSize += buf;

	UpdateData(FALSE);

	Disconnect();
}

void CU2S_GUIDlg::OnSelchangeCombo1() 
{
	OnUpdateInfo();	
}

void CU2S_GUIDlg::OnModUnlock() 
{
	if(Connect(0x81)) {
//		u2s.SelectMode(0x81);
		u2s.ModUnlock();
	}
	Disconnect();
}

//-----------------------------------------------------------------------------

bool CU2S_GUIDlg::SelectMode(BYTE b)
{
	if(Connect(b)) {
//		u2s.SelectMode(b);
	}else{
		Disconnect();
		return false;
	}
	Disconnect();
	return true;
}

void CU2S_GUIDlg::OnSetToApp() 
{
	SelectMode(0x01); // valid values 0 to 0xF ONLY
}

void CU2S_GUIDlg::OnSetToDebug() 
{
	if(Connect(0x80)) {
//		u2s.SelectMode(0x80);
		if((u2s.GetMode() & 0x8F) == 0x80) {
			DebugDlg dd(this);
			dd.DoModal();
		}
		Disconnect();
	}
}
void CU2S_GUIDlg::OnSetToBL() 
{
	SelectMode(0x81);
}

void CU2S_GUIDlg::OnSetToSTK500()
{
	SelectMode(0x82);
}

void CU2S_GUIDlg::OnSetToJTAG() 
{
	SelectMode(0x83);
}

void CU2S_GUIDlg::OnSetToUART() 
{
	SelectMode(0x84);
}

void CU2S_GUIDlg::OnSetToDW() 
{
	SelectMode(0x85);
}

//-----------------------------------------------------------------------------
