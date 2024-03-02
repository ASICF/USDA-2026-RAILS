import { includes } from "lodash";
import React, { Fragment, useState } from "react";
import axios from "axios";
import {
  Header,
  Icon,
  Message,
  Segment,
  Breadcrumb,
  Checkbox,
  Button,
  Divider,
  ButtonContent
} from "semantic-ui-react";

import Breadcrumbs from "../Shared/Breadcrumb";
import MessageBox from "../Shared/MessageBox";
import Skeleton, { SkeletonTheme } from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";
import { AnimationOnScroll } from "react-animation-on-scroll";
import "animate.css/animate.min.css";
import ScrollIntoView from "react-scroll-into-view";

function Mailgroups(props) {
  const [message, setMessage] = useState(null);
  const [data, setData] = useState(props.active_mail_groups);
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
  console.log(data);

  const onSubmit = () => {
    setMessage(null);
    setSubmitted(true)
    setLoading(true)
    axios
      .post(`mail_groups`, {
        mail_groups_ids: data,
        authenticity_token: props.token,
      })
      .then(({ data }) => {
        setLoading(false)
        setSubmitted(false )
        if (data.state) {
          setMessage({
            status: "Success",
            text: data.message,
          });
        } else {
          setMessage({
            status: "Error",
            text: data.message,
          });
        }
      })
      .catch((err) => {
        console.log(err);
      });
  };
  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section id="top">Manage</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Icon name="mail" />
        <Breadcrumb.Section active>Email Notifications</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {message && <MessageBox status={message.status} message={message.text} />}

      {props.mail_groups.map((record) => {
        return (
            <Fragment key={record.id} style={{marginBottom: "20px"} }>
              <Header as="h5" attached="top" className='mailgroup-animation'>
                {record.name || <Skeleton />}
                {/* <Divider /> */}
                {/* <Checkbox toggle floated="right" checked /> */}
              </Header>
              <Segment attached clearing className='mailgroup-animation' style={{marginBottom: "20px"}}>
                {record.description || <Skeleton />}
                <Divider />
                <Checkbox
                  value={record.id}
                  toggle
                  onChange={(e, { checked, value }) => {
                    var records = [...data];
                    var includes = data.includes(value);

                    if (checked && !includes) {
                      records.push(value);
                      setData(records);
                    } else if (!checked && includes) {
                      setData(records.filter((record) => record !== value));
                    }
                  }}
                  checked={data.includes(record.id)}
                  style={{ float: "right" }}
                />
              </Segment>
            </Fragment>
        );
      })}
      <Divider />
      <div>
        <ScrollIntoView selector="#top">
          <Button
            primary
            animated
            type="submit"
            loading={submitted}
            disabled={submitted}
            onClick={onSubmit}
            style={{
              margin: "auto",
              width: "25%",
              padding: "10px",
              display: "flex",
            }}
          >
             <ButtonContent visible>Submit</ButtonContent>
          <ButtonContent hidden>
          <Icon name='arrow right' />
          </ButtonContent>
          </Button>
        </ScrollIntoView>
        <br />
        <br />
      </div>
    </div>
  );
}

export default Mailgroups;
