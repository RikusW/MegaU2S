// U2S_SettingsDlg.cpp : implementation file
//

#include "stdafx.h"
#include "U2S_GUI.h"
#include "SettingsDlg.h"

#include "U2S.h"
extern U2S u2s;

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

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
	ON_BN_CLICKED(IDC_BDEFAULTS, OnBDefaults)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CU2S_SettingsDlg message handlers

//-----------------------------------------------

BYTE def[16] = { 0x81, 2, 2, 10, 0xB0, 48, 0, 0, 0, 2, 0, 0xFF, 0xFF, 0, 0xFF, 1 };
BYTE set[16];

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

//-----------------------------------------------

void CU2S_SettingsDlg::OnBDefaults() 
{
	memcpy(set,def,16);
	m_Msg = "Setting defaults";

	m_CMode.SetCurSel(FindMode(set[0]));
	m_CISP.SetCurSel(FindSpeed(set[9]));

	UpdateData(FALSE);
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

/////////////////////////////////////////////////////////////////////////////

BOOL CU2S_SettingsDlg::OnInitDialog()
{
	CDialog::OnInitDialog();

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

	m_CMode.SetCurSel(-1);
	m_CISP.SetCurSel(-1);

	m_Msg = "Connected";
	UpdateData(FALSE);

	u8 *p;
	u2s.SetAddress(0x3F0);
	u2s.ReadEeprom(&p,16);
	memcpy(set,p,16);

	m_CMode.SetCurSel(FindMode(set[0]));
	m_CISP.SetCurSel(FindSpeed(set[9]));
	
	return TRUE;  // return TRUE  unless you set the focus to a control
}

//-----------------------------------------------
