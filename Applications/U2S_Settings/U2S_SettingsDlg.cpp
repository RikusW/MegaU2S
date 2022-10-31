// U2S_SettingsDlg.cpp : implementation file
//

#include "stdafx.h"
#include "U2S_Settings.h"
#include "U2S_SettingsDlg.h"

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
// CU2S_SettingsDlg dialog

CU2S_SettingsDlg::CU2S_SettingsDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CU2S_SettingsDlg::IDD, pParent)
{
	//{{AFX_DATA_INIT(CU2S_SettingsDlg)
	m_Msg = _T("");
	//}}AFX_DATA_INIT
	// Note that LoadIcon does not require a subsequent DestroyIcon in Win32
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
}

void CU2S_SettingsDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CU2S_SettingsDlg)
	DDX_Control(pDX, IDC_COMBO_MODE, m_CMode);
	DDX_Control(pDX, IDC_COMBO_ISP, m_CISP);
	DDX_Text(pDX, IDC_EMSG, m_Msg);
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CU2S_SettingsDlg, CDialog)
	//{{AFX_MSG_MAP(CU2S_SettingsDlg)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	ON_BN_CLICKED(IDC_BREFRESH, OnBRefresh)
	ON_BN_CLICKED(IDC_BDEFAULTS, OnBDefaults)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CU2S_SettingsDlg message handlers

BOOL CU2S_SettingsDlg::OnInitDialog()
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
	m_CMode.AddString("0x81 Bootloader");
	m_CMode.AddString("0x82 STK500");
	m_CMode.AddString("0x83 JTAGICE mki");
	m_CMode.AddString("0x84 USART");
	m_CMode.AddString("0x01 App");
	m_CMode.AddString("0x41 App NO USB");

	m_CISP.AddString("2000kHz");
	m_CISP.AddString("500kHz");
	m_CISP.AddString("125kHz");
	m_CISP.AddString("62.5kHz");
	m_CISP.AddString("4333Hz");
	m_CISP.AddString("1300Hz");

	OnBRefresh();
	
	return TRUE;  // return TRUE  unless you set the focus to a control
}

void CU2S_SettingsDlg::OnSysCommand(UINT nID, LPARAM lParam)
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

void CU2S_SettingsDlg::OnPaint() 
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
HCURSOR CU2S_SettingsDlg::OnQueryDragIcon()
{
	return (HCURSOR) m_hIcon;
}

//-----------------------------------------------

BYTE def[16] = { 0x81, 2, 2, 10, 0xB0, 48, 0, 0, 0, 2, 0, 0xFF, 0xFF, 0, 0xFF, 1 };
BYTE set[16];


void CU2S_SettingsDlg::OnBDefaults() 
{
	memcpy(set,def,16);
	m_Msg = "Setting defaults";
	UpdateData(FALSE);
}


//-----------------------------------------------
//reading

BYTE modes[] = { 0x81, 0x82, 0x83, 0x84, 0x01, 0x41 };
BYTE speed[] = { 0x00, 0x01, 0x02, 0x03, 0x4C, 0xFE };

int FindMode(BYTE b)
{
	for(int i = 0; i < sizeof(modes); i++) {
		if(modes[i] == b)
			return i;
	}
	return 0;
}

int FindSpeed(BYTE b)
{
	for(int i = 0; i < sizeof(speed); i++) {
		if(speed[i] == b)
			return i;
	}
	return 2;
}

void CU2S_SettingsDlg::OnBRefresh() 
{
	m_CMode.SetCurSel(-1);
	m_CISP.SetCurSel(-1);

	if(!u2s.Connect("COM3",0x81)) {
		m_Msg = "Failed to connect";
		UpdateData(FALSE);
		return;
	}

	Sleep(500);

	if(!u2s.SignOn()) {
		m_Msg = "Failed to Sign On";
		UpdateData(FALSE);
		return;
	}

	m_Msg = "Connected";
	UpdateData(FALSE);

	u8 *p;
	u2s.SetAddress(0x3F0);
	u2s.ReadEeprom(&p,16);
	memcpy(set,p,16);

	m_CMode.SetCurSel(FindMode(p[0]));
	m_CISP.SetCurSel(FindSpeed(p[9]));
}

//-----------------------------------------------
//writing

void CU2S_SettingsDlg::OnOK() 
{
	int m = m_CMode.GetCurSel();
	int i = m_CISP.GetCurSel();

	set[0] = modes[m];
	set[9] = speed[i];

	u2s.SetAddress(0x3F0);
	u2s.WriteEeprom(set,16);

	CDialog::OnOK();
}

//-----------------------------------------------

BOOL CU2S_SettingsDlg::DestroyWindow() 
{
	u2s.Disconnect();
	return CDialog::DestroyWindow();
}

//-----------------------------------------------
