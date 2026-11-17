import XCTest
@testable import Hopes

final class ChatMarkdownTests: XCTestCase {
    func testParsesFigmaAnswerIntoBlocks() {
        let markdown = """
        ## Frontend 시작 순서
        처음에는 화면을 직접 만들어 보는 것부터 시작하는 걸 추천해요.
        1. HTML·CSS로 간단한 페이지 만들기
        2. JavaScript 기초 문법 익히기
        ```html
        <button class="primary">
          질문하기
        </button>
        ```
        > 막히면 선배에게 바로 물어보는 게 제일 빨라요.
        [학교 전공 소개 페이지 보기](https://gsm.hs.kr)
        """
        let blocks = ChatMarkdownParser.parse(markdown)
        XCTAssertEqual(blocks.count, 6)
        XCTAssertEqual(blocks[0], .heading("Frontend 시작 순서"))
        XCTAssertEqual(blocks[2], .orderedList(["HTML·CSS로 간단한 페이지 만들기", "JavaScript 기초 문법 익히기"]))
        XCTAssertEqual(blocks[3], .code(language: "html", text: #"<button class="primary">"# + "\n  질문하기\n</button>"))
        XCTAssertEqual(blocks[4], .quote("막히면 선배에게 바로 물어보는 게 제일 빨라요."))
        XCTAssertEqual(blocks[5], .link(title: "학교 전공 소개 페이지 보기", url: URL(string: "https://gsm.hs.kr")!))
    }

    func testRejectsNonWebLinksAndKeepsUnclosedCode() {
        let blocks = ChatMarkdownParser.parse("[앱 열기](javascript:alert(1))\n```\nlet a = 1")
        XCTAssertEqual(blocks.first, .paragraph("[앱 열기](javascript:alert(1))"))
        XCTAssertEqual(blocks.last, .code(language: "", text: "let a = 1"))
    }

    func testBulletsAndParagraphsSeparate() {
        let blocks = ChatMarkdownParser.parse("- 하나\n- 둘\n\n끝 문장")
        XCTAssertEqual(blocks, [.bulletList(["하나", "둘"]), .paragraph("끝 문장")])
    }

    func testRelatedQuestionsSkipCurrentAndDuplicates() {
        let result = ChatConversationViewController.relatedQuestions(
            from: ["기숙사 하루 일과가 어떻게 돼?", "포트폴리오는 언제?", "포트폴리오는 언제?", " ", "동아리는?"],
            excluding: "기숙사 하루 일과가 어떻게 돼?"
        )
        XCTAssertEqual(result, ["포트폴리오는 언제?", "동아리는?"])
    }
}
