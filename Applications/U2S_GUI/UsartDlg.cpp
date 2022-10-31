// UartDlg.cpp : implementation file
//

#include "stdafx.h"
#include "u2s_gui.h"
#include "UsartDlg.h"

#include "U2S.h"
extern U2S u2s;
#include "U2S_Debug.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// UartDlg dialog


UartDlg::UartDlg(CWnd* pParent /*=NULL*/)
	: CDialog(UartDlg::IDD, pParent)
{
	//{{AFX_DATA_INIT(UartDlg)
	m_EnRtsCts = FALSE;
	m_EnRX = TRUE;
	m_EnTX = TRUE;
	m_EnRTS = FALSE;
	m_EnCTS = FALSE;
	m_EnU2X = TRUE;
	m_CMode = 0;
	m_CDataBits = 3;
	m_CParity = 0;
	m_CStopBits = 0;
	m_CClockEdge = 0;
	m_UBRR = _T("207");
	m_Baud = _T("9615");
	//}}AFX_DATA_INIT
}


void UartDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(UartDlg)
	DDX_Check(pDX, IDC_CHECK1, m_EnRtsCts);
	DDX_Check(pDX, IDC_CHECK2, m_EnRX);
	DDX_Check(pDX, IDC_CHECK3, m_EnTX);
	DDX_Check(pDX, IDC_CHECK4, m_EnRTS);
	DDX_Check(pDX, IDC_CHECK5, m_EnCTS);
	DDX_Check(pDX, IDC_CHECK6, m_EnU2X);
	DDX_CBIndex(pDX, IDC_COMBO1, m_CMode);
	DDX_CBIndex(pDX, IDC_COMBO2, m_CDataBits);
	DDX_CBIndex(pDX, IDC_COMBO3, m_CParity);
	DDX_CBIndex(pDX, IDC_COMBO4, m_CStopBits);
	DDX_CBIndex(pDX, IDC_COMBO5, m_CClockEdge);
	DDX_Text(pDX, IDC_EDIT1, m_UBRR);
	DDX_Text(pDX, IDC_EDIT2, m_Baud);
	//}}AFX_DATA_MAP
}


BEGIN_MESSAGE_MAP(UartDlg, CDialog)
	//{{AFX_MSG_MAP(UartDlg)
	ON_BN_CLICKED(IDC_RADIO1, OnRadioStd)
	ON_BN_CLICKED(IDC_RADIO2, OnRadioNonStd)
	ON_BN_CLICKED(IDC_RADIO3, OnRadioBaudOver)
	ON_BN_CLICKED(IDC_RADIO4, OnRadioSetupOver)
	ON_EN_CHANGE(IDC_EDIT1, OnChangeEditUBRR)
	ON_EN_CHANGE(IDC_EDIT2, OnChangeEditBaud)
	ON_BN_CLICKED(IDC_CHECK6, OnCheck6)
	ON_CBN_SELCHANGE(IDC_COMBO1, OnSelchangeCombo1)
	ON_CBN_SELCHANGE(IDC_COMBO2, OnSelchangeCombo2)
	ON_CBN_SELCHANGE(IDC_COMBO3, OnSelchangeCombo3)
	ON_CBN_SELCHANGE(IDC_COMBO4, OnSelchangeCombo4)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// UartDlg message handlers

#define RS232_BAUD_NONSTD   0
#define RS232_BAUD_OVERRIDE 1
#define RS232_HW_FLOW_CTRL  2
#define RS232_SETUP_OVERRIDE 3

BOOL UartDlg::OnInitDialog() 
{
	CDialog::OnInitDialog();

	UpdateData(TRUE);

	u8 *p,ubl,ubh,rs232;
	u8 set[16];
	u2s.SetAddress(0x3F0);
	u2s.ReadEeprom(&p,16);
	memcpy(set,p,16);
	ubl = set[5]; //48
	ubh = set[6]; //0
	rs232 = set[10];

	if(rs232 & (1<<RS232_HW_FLOW_CTRL)) {
		m_EnRtsCts = 1;
		UpdateData(FALSE);
	}


	switch(rs232 & 0x0B) {
	case 0: //std
		EnableOverride(0);
		CheckRadioButton(IDC_RADIO1,IDC_RADIO4,IDC_RADIO1);
		break;
	case 1: //nonstd
		EnableOverride(1);
		CheckRadioButton(IDC_RADIO1,IDC_RADIO4,IDC_RADIO2);
		break;
	case 2: //baud over
		EnableOverride(2);
		CheckRadioButton(IDC_RADIO1,IDC_RADIO4,IDC_RADIO3);
		{
			int b = ubh;
			b <<= 8;
			b |= ubl;
			char buf[20];
			itoa(b,buf,10);
			m_UBRR = buf;
			UpdateData(FALSE);
			OnChangeEditUBRR();
		}
		break;
	case 8: //setup over
		EnableOverride(3);
		CheckRadioButton(IDC_RADIO1,IDC_RADIO4,IDC_RADIO4);
		break;
	}
	
	return TRUE;  // return TRUE unless you set the focus to a control
	              // EXCEPTION: OCX Property Pages should return FALSE
}

void UartDlg::OnOK() 
{
	UpdateData(TRUE);

	u8 a=0,b=0,c=0,d=0,rs232,ubl,ubh;
	int UBRR = atoi(m_UBRR);
	UBRR &= 0xFFF;

	u8 *p;
	u8 set[16];
	u2s.SetAddress(0x3F0);
	u2s.ReadEeprom(&p,16);
	memcpy(set,p,16);
	ubl = set[5]; //48
	ubh = set[6]; //0
	rs232 = set[10];
	u2s.SelectMode(0xA0);
	
	if(rs232 & (1<<RS232_BAUD_OVERRIDE)) {
		ubl = 48;
		ubh = 0;
	}

	rs232 &= 0xF0;
	if(m_EnRtsCts) {
		rs232 |= (1<<RS232_HW_FLOW_CTRL);
	}

	switch(radio) {
	case 0: //Standard baud
		break;
	case 1:
		rs232 |= (1<<RS232_BAUD_NONSTD);
		break;
	case 2:
		rs232 |= (1<<RS232_BAUD_OVERRIDE);
		ubh = (UBRR >> 8) & 0xFF;
		ubl = UBRR & 0xFF;
		break;
	case 3:
		rs232 &= 0xF0;
		rs232 |= (1<<RS232_SETUP_OVERRIDE);

		if(m_EnU2X && (m_CMode == 0)) {
			a = (1<<U2X1);
		}
		if(m_EnRX) {
			b |= (1<<RXEN1);
		}
		if(m_EnTX) {
			b |= (1<<TXEN1);
		}
		if(m_EnRTS) {
			d |= (1<<RTSEN);
		}
		if(m_EnCTS) {
			d |= (1<<CTSEN);
		}

		PORTD = 0x08;
		switch(m_CMode) {
		case 0:
			DDRD = 0x08; // asynchronous
			break;
		case 1:
			c |= (1<<UMSEL10); //synchronous master
			DDRD = 0x28;
			break;
		case 2:
			c |= (1<<UMSEL10); //synchronous slave
			DDRD = 0x08;
			break;
		}

		c |= (m_CDataBits << 1) & 6;

		switch(m_CParity) {
		case 0: break; //none
		case 1: c |= (1<<UPM11); break; //even
		case 2: c |= (1<<UPM11)|(1<<UPM10);  break; //odd
		}

		if(m_CStopBits) {
			c |= (1<<USBS1);
		}
		if(m_CClockEdge) {
			c |= (1<<UCPOL1);
		}

 		UBRR1H = (UBRR >> 8) & 0xFF;
		UBRR1L = UBRR & 0xFF;
		UCSR1D = d;
		UCSR1C = c;
		UCSR1A = a;
		UCSR1B = b; //enable it

		break;
	}

	u2s.SelectMode(0xA1);
	set[5] = ubl;
	set[6] = ubh;
	set[10] = rs232;
  	u2s.SetAddress(0x3F0);
	u2s.WriteEeprom(set,16); //only values that actually change will be written

	u2s.SelectMode(0x84);
	CDialog::OnOK();
}

void UartDlg::OnRadioStd() 
{
	EnableOverride(0);
}

void UartDlg::OnRadioNonStd() 
{
	EnableOverride(1);
}

void UartDlg::OnRadioBaudOver() 
{
	EnableOverride(2);
}

void UartDlg::OnRadioSetupOver() 
{
	EnableOverride(3);
}

void UartDlg::EnableOverride(int i)
{
	radio = i;
	UpdateData(TRUE);

	GetDlgItem(IDC_CHECK1)->EnableWindow(i != 3);

	GetDlgItem(IDC_CHECK2)->EnableWindow(i == 3);
	GetDlgItem(IDC_CHECK3)->EnableWindow(i == 3);
	GetDlgItem(IDC_CHECK4)->EnableWindow(i == 3);
	GetDlgItem(IDC_CHECK5)->EnableWindow(i == 3);
	GetDlgItem(IDC_CHECK6)->EnableWindow(i == 3 && m_CMode == 0);

	GetDlgItem(IDC_COMBO1)->EnableWindow(i == 3);
	GetDlgItem(IDC_COMBO2)->EnableWindow(i == 3);
	GetDlgItem(IDC_COMBO3)->EnableWindow(i == 3);
	GetDlgItem(IDC_COMBO4)->EnableWindow(i == 3);
	GetDlgItem(IDC_COMBO5)->EnableWindow(i == 3 && m_CMode > 0);

	GetDlgItem(IDC_EDIT1)->EnableWindow(i == 3 || i == 2);
	GetDlgItem(IDC_EDIT2)->EnableWindow(i == 3 || i == 2);
	GetDlgItem(IDC_STATIC1)->EnableWindow(i == 3 || i == 2);
	GetDlgItem(IDC_STATIC2)->EnableWindow(i == 3 || i == 2);

	if(i < 2) {
		UpdateData(TRUE);
		m_UBRR = "207";
		m_Baud = "9615";
		UpdateData(FALSE);
	}

	if(i != 3) {
		CheckDlgButton(IDC_CHECK6,1);
	}
	OnChangeEditUBRR();
}

/////////////////////////////////////////////////////////////////////////////

char dt[] = "5678";
char pa[] = "NEO";
char st[] = "12";
#define MIN(a,b) (a > b ? b : a)

void UartDlg::ShowRealBaud()
{
	int baud;
	int UBRR = atoi(m_UBRR);
	UBRR &= 0xFFF;

	if(m_CMode > 0 && radio == 3) {
		baud = 16000000 / ( 2 * (UBRR + 1));
	}else if(m_EnU2X) {
		baud = 16000000 / ( 8 * (UBRR + 1));
	}else{
		baud = 16000000 / (16 * (UBRR + 1));
	}

	char buf[30];
	itoa(baud,buf,10);
	strcat(buf," - ");
	char *p = buf + strlen(buf);
	*p++ = dt[MIN(m_CDataBits,3)];
	*p++ = pa[MIN(m_CParity,2)];
	*p++ = st[MIN(m_CStopBits,1)];
	*p = 0;
	
	GetDlgItem(IDC_STATIC_BAUD)->SetWindowText(buf);
}

void UartDlg::OnChangeEditUBRR() 
{
	UpdateData(TRUE);

	int Baud = 0, UBRR = atoi(m_UBRR);

	if(m_CMode > 0 && radio == 3) {
		Baud = 16000000 / ( 2 * (UBRR + 1));
	}else if(m_EnU2X) {
		Baud = 16000000 / ( 8 * (UBRR + 1));
	}else{
		Baud = 16000000 / (16 * (UBRR + 1));
	}

	char buf[30];
	itoa(Baud,buf,10);
	m_Baud = buf;

	UpdateData(FALSE);
	ShowRealBaud();
}

void UartDlg::OnChangeEditBaud() 
{
	UpdateData(TRUE);

	int UBRR = 0, Baud = atoi(m_Baud);

	if(m_CMode > 0 && radio == 3) {
		UBRR = (16000000 / ( 2 * Baud)) - 1;
	}else if(m_EnU2X) {
		UBRR = (16000000 / ( 8 * Baud)) - 1;
	}else{
		UBRR = (16000000 / (16 * Baud)) - 1;
	}

	if(UBRR < 0) {
		UBRR = 0;
	}
	char buf[30];
	itoa(UBRR,buf,10);
	m_UBRR = buf;

	UpdateData(FALSE);
	ShowRealBaud();
}

void UartDlg::OnCheck6() 
{
	OnChangeEditUBRR();	
}

/////////////////////////////////////////////////////////////////////////////

void UartDlg::OnSelchangeCombo1() 
{
	OnChangeEditUBRR();	
	GetDlgItem(IDC_COMBO5)->EnableWindow(m_CMode > 0);
	GetDlgItem(IDC_CHECK6)->EnableWindow(m_CMode == 0);
}

void UartDlg::OnSelchangeCombo2() 
{
	OnChangeEditUBRR();	
}

void UartDlg::OnSelchangeCombo3() 
{
	OnChangeEditUBRR();	
}

void UartDlg::OnSelchangeCombo4() 
{
	OnChangeEditUBRR();	
}

/////////////////////////////////////////////////////////////////////////////
