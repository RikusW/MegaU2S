#if !defined(AFX_UARTDLG_H__BF360ECF_A437_4B56_91F8_2CF58CD1F25C__INCLUDED_)
#define AFX_UARTDLG_H__BF360ECF_A437_4B56_91F8_2CF58CD1F25C__INCLUDED_

#if _MSC_VER >= 1000
#pragma once
#endif // _MSC_VER >= 1000
// UartDlg.h : header file
//

/////////////////////////////////////////////////////////////////////////////
// UartDlg dialog

class UartDlg : public CDialog
{
// Construction
public:
	UartDlg(CWnd* pParent = NULL);   // standard constructor

// Dialog Data
	//{{AFX_DATA(UartDlg)
	enum { IDD = IDD_U2S_USART };
	BOOL	m_EnRtsCts;
	BOOL	m_EnRX;
	BOOL	m_EnTX;
	BOOL	m_EnRTS;
	BOOL	m_EnCTS;
	BOOL	m_EnU2X;
	int		m_CMode;
	int		m_CDataBits;
	int		m_CParity;
	int		m_CStopBits;
	int		m_CClockEdge;
	CString	m_UBRR;
	CString	m_Baud;
	//}}AFX_DATA

	void EnableOverride(int);
	void ShowRealBaud();
	int radio;

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(UartDlg)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:

	// Generated message map functions
	//{{AFX_MSG(UartDlg)
	virtual void OnOK();
	afx_msg void OnRadioStd();
	afx_msg void OnRadioNonStd();
	afx_msg void OnRadioBaudOver();
	afx_msg void OnRadioSetupOver();
	virtual BOOL OnInitDialog();
	afx_msg void OnChangeEditUBRR();
	afx_msg void OnChangeEditBaud();
	afx_msg void OnCheck6();
	afx_msg void OnSelchangeCombo1();
	afx_msg void OnSelchangeCombo2();
	afx_msg void OnSelchangeCombo3();
	afx_msg void OnSelchangeCombo4();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_UARTDLG_H__BF360ECF_A437_4B56_91F8_2CF58CD1F25C__INCLUDED_)
